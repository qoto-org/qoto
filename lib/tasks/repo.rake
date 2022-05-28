# frozen_string_literal: true

REPOSITORY_NAME = 'mastodon/mastodon'

namespace :repo do
  desc 'Generate the AUTHORS.md file'
  task :authors do
    file = File.open(Rails.root.join('AUTHORS.md'), 'w')

    file << <<~HEADER
      Authors
      =======

      Mastodon is available on [GitHub](https://github.com/#{REPOSITORY_NAME})
      and provided thanks to the work of the following contributors:

    HEADER

    url = "https://api.github.com/repos/#{REPOSITORY_NAME}/contributors?anon=1"

    HttpLog.config.compact_log = true

    while url.present?
      response     = HTTP.get(url)
      contributors = Oj.load(response.body)

      contributors.each do |c|
        file << "* [#{c['login']}](#{c['html_url']})\n" if c['login']
        file << "* [#{c['name']}](mailto:#{c['email']})\n" if c['name']
      end

      url = LinkHeader.parse(response.headers['Link']).find_link(%w(rel next))&.href
    end

    file << <<~FOOTER

      This document is provided for informational purposes only. Since it is only updated once per release, the version you are looking at may be currently out of date. To see the full list of contributors, consider looking at the [git history](https://github.com/mastodon/mastodon/graphs/contributors) instead.
    FOOTER
  end

  desc 'Replace pull requests with authors in the CHANGELOG.md file'
  task :changelog do
    path = Rails.root.join('CHANGELOG.md')
    tmp  = Tempfile.new

    HttpLog.config.compact_log = true

    begin
      File.open(path, 'r') do |file|
        file.each_line do |line|
          if line.start_with?('-')
            new_line = line.gsub(/#([[:digit:]]+)*/) do |pull_request_reference|
              pull_request_number = pull_request_reference[1..-1]
              response = nil

              loop do
                response = HTTP.headers('Authorization' => "token #{ENV['GITHUB_API_TOKEN']}").get("https://api.github.com/repos/#{REPOSITORY_NAME}/pulls/#{pull_request_number}")

                if response.code == 403
                  sleep_for = (response.headers['X-RateLimit-Reset'].to_i - Time.now.to_i).abs
                  puts "Sleeping for #{sleep_for} seconds to get over rate limit"
                  sleep sleep_for
                else
                  break
                end
              end

              pull_request = Oj.load(response.to_s)
              "[#{pull_request['user']['login']}](#{pull_request['html_url']})"
            end

            tmp.puts new_line
          else
            tmp.puts line
          end
        end
      end

      tmp.close
      FileUtils.mv(tmp.path, path)
    ensure
      tmp.close
      tmp.unlink
    end
  end

  task check_locales_files: :environment do
    pastel = Pastel.new

    missing_yaml_files = I18n.available_locales.reject { |locale| File.exist?(Rails.root.join('config', 'locales', "#{locale}.yml")) }
    missing_json_files = I18n.available_locales.reject { |locale| File.exist?(Rails.root.join('app', 'javascript', 'mastodon', 'locales', "#{locale}.json")) }

    locales_in_files = Dir[Rails.root.join('config', 'locales', '*.yml')].map do |path|
      file_name = File.basename(path)
      file_name.gsub(/\A(doorkeeper|devise|activerecord|simple_form)\./, '').gsub(/\.yml\z/, '').to_sym
    end.uniq.compact

    missing_available_locales = locales_in_files - I18n.available_locales
    supported_locale_codes    = Set.new(LanguagesHelper::SUPPORTED_LOCALES.keys + LanguagesHelper::REGIONAL_LOCALE_NAMES.keys)
    missing_locale_names      = I18n.available_locales.reject { |locale| supported_locale_codes.include?(locale) }

    critical = false

    unless missing_json_files.empty?
      critical = true

      puts pastel.red("You are missing JSON files for these locales: #{pastel.bold(missing_json_files.join(', '))}")
      puts pastel.red('This will lead to runtime errors for users who have selected those locales')
      puts pastel.red("Add the missing files or remove the locales from #{pastel.bold('I18n.available_locales')} in config/application.rb")
    end

    unless missing_yaml_files.empty?
      critical = true

      puts pastel.red("You are missing YAML files for these locales: #{pastel.bold(missing_yaml_files.join(', '))}")
      puts pastel.red('This will lead to runtime errors for users who have selected those locales')
      puts pastel.red("Add the missing files or remove the locales from #{pastel.bold('I18n.available_locales')} in config/application.rb")
    end

    unless missing_available_locales.empty?
      puts pastel.yellow("You have locale files that are not enabled: #{pastel.bold(missing_available_locales.join(', '))}")
      puts pastel.yellow("Add them to #{pastel.bold('I18n.available_locales')} in config/application.rb or remove them")
    end

    unless missing_locale_names.empty?
      puts pastel.yellow("You are missing human-readable names for these locales: #{pastel.bold(missing_locale_names.join(', '))}")
      puts pastel.yellow("Add them to app/helpers/languages_helper.rb or remove the locales from #{pastel.bold('I18n.available_locales')} in config/application.rb")
    end

    if critical
      exit(1)
    else
      puts pastel.green('OK')
    end
  end

  task generate_mailer_assets: :environment do
    rsvg_convert = Terrapin::CommandLine.new('rsvg-convert', '-w :w -h :h :input -o :output')
    output_dest  = Rails.root.join('app', 'javascript', 'images', 'mailer')

    # Displayed size is 64px, at 3x it's 192px
    Dir[Rails.root.join('app', 'javascript', 'images', 'icons', '*.svg')].each do |path|
      rsvg_convert.run(input: path, w: 192, h: 192, output: output_dest.join("#{File.basename(path, '.svg')}.png"))
    end

    # Displayed size is 34px, at 3x it's 102px
    rsvg_convert.run(input: Rails.root.join('app', 'javascript', 'images', 'logo-symbol-wordmark.svg'), w: (102 * (261.0/66)).ceil, h: 102, output: output_dest.join("wordmark.png"))

    # Displayed size is 24px, at 3x it's 72px
    rsvg_convert.run(input: Rails.root.join('app', 'javascript', 'images', 'logo-symbol-icon.svg'), w: (72 * (61.0/65)).ceil, h: 72, output: output_dest.join("logo.png"))
  end

  task generate_app_icons: :environment do
    favicon_source  = Rails.root.join('app', 'javascript', 'images', 'logo.svg')
    app_icon_source = Rails.root.join('app', 'javascript', 'images', 'app-icon.svg')
    output_dest     = Rails.root.join('app', 'javascript', 'icons')

    rsvg_convert = Terrapin::CommandLine.new('rsvg-convert', '-w :size -h :size :input -o :output')
    convert = Terrapin::CommandLine.new('convert', ':input :output')

    favicon_sizes      = [16, 32, 48]
    apple_icon_sizes   = [57, 60, 72, 76, 114, 120, 144, 152, 167, 180, 1024]
    android_icon_sizes = [36, 48, 72, 96, 144, 192, 256, 384, 512]

    favicons = []

    favicon_sizes.each do |size|
      output_path = output_dest.join("favicon-#{size}x#{size}.png")
      favicons << output_path
      rsvg_convert.run(size: size, input: favicon_source, output: output_path)
    end

    convert.run(input: favicons, output: Rails.root.join('public', 'favicon.ico'))

    apple_icon_sizes.each do |size|
      rsvg_convert.run(size: size, input: app_icon_source, output: output_dest.join("apple-touch-icon-#{size}x#{size}.png"))
    end

    android_icon_sizes.each do |size|
      rsvg_convert.run(size: size, input: app_icon_source, output: output_dest.join("android-chrome-#{size}x#{size}.png"))
    end
  end
end
