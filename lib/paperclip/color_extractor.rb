# frozen_string_literal: true

require 'mime/types/columnar'

module Paperclip
  class ColorExtractor < Paperclip::Processor
    MIN_CONTRAST = (500.0/255.0)

    def make
      depth = 8

      # Determine background palette by getting colors close to the image's edge only
      background_palette = palette_from_histogram(convert(':source -crop :crop -format %c -colors :quantity -depth :depth histogram:info:', source: File.expand_path(@file.path), quantity: 4, depth: depth, crop: '50%x100%'), 4)
      background_color   = background_palette.last

      # Determine foreground palette from the whole image
      foreground_palette = palette_from_histogram(convert(':source -format %c -colors :quantity -depth :depth histogram:info:', source: File.expand_path(@file.path), quantity: 10, depth: depth), 10)
      foreground_colors  = []

      2.times do
        max_distance = 0

        foreground_palette.each do |color|
          distance = ColorDiff.between(background_color, color)
          contrast = w3c_contrast(background_color, color)

          if distance > max_distance && contrast >= MIN_CONTRAST && !foreground_colors.include?(color)
            max_distance = distance
            foreground_colors << color
          end
        end
      end

      start_by = 50

      # If we don't have enough colors for accent and foreground, generate
      # new ones by manipulating the background color
      (2 - foreground_colors.size).times do
        foreground_colors << lighten_or_darken(background_color, start_by)
        start_by += 25
      end

      # We want the less satured color to be the foreground color (buttons, text)
      # and the more satured to be the "accent"
      foreground_colors.sort_by! { |rgb| rgb_to_hsl(rgb.r, rgb.g, rgb.b)[1] }

      meta = {
        colors: {
          background: rgb_to_hex(background_color),
          foreground: rgb_to_hex(foreground_colors[0]),
          accent: rgb_to_hex(foreground_colors[1]),
        },
      }

      attachment.instance.file.instance_write(:meta, (attachment.instance.file.instance_read(:meta) || {}).merge(meta))

      @file
    end

    private

    def w3c_contrast(a, b)
      r = (a.r - b.r).abs
      g = (a.g - b.g).abs
      b = (a.b - b.b).abs

      r + g + b
    end

    def rgb_to_hsl(r, g, b)
      r /= 255.0
      g /= 255.0
      b /= 255.0
      max = [r, g, b].max
      min = [r, g, b].min
      h = (max + min) / 2.0
      s = (max + min) / 2.0
      l = (max + min) / 2.0

      if(max == min)
        h = 0
        s = 0 # achromatic
      else
        d = max - min;
        s = l >= 0.5 ? d / (2.0 - max - min) : d / (max + min)
        case max
          when r
            h = (g - b) / d + (g < b ? 6.0 : 0)
          when g
            h = (b - r) / d + 2.0
          when b
            h = (r - g) / d + 4.0
        end
        h /= 6.0
      end

      [(h*360).round, (s*100).round, (l*100).round]
    end

    def hsl_to_rgb(h, s, l)
      h = h/360.0
      s = s/100.0
      l = l/100.0

      r = 0.0
      g = 0.0
      b = 0.0

      if(s == 0.0)
        r = l.to_f
        g = l.to_f
        b = l.to_f # achromatic
      else
        q = l < 0.5 ? l * (1 + s) : l + s - l * s
        p = 2 * l - q
        r = hue_to_rgb(p, q, h + 1/3.0)
        g = hue_to_rgb(p, q, h)
        b = hue_to_rgb(p, q, h - 1/3.0)
      end

      [(r * 255).round, (g * 255).round, (b * 255).round]
    end

    def lighten_or_darken(color, by)
      hue, saturation, light = rgb_to_hsl(color.r, color.g, color.b)

      if light < 0.5
        light += by
      else
        light -= by
      end

      ColorDiff::Color::RGB.new(*hsl_to_rgb(hue, saturation, light))
    end

    def palette_from_histogram(result, quantity)
      frequencies       = result.scan(/([0-9]+)\:/).flatten.map(&:to_f)
      hex_values        = result.scan(/(\#[0-9ABCDEF]{6,8})/).flatten
      total_frequencies = frequencies.reduce(&:+).to_f

      frequencies.map.with_index { |f, i| [f / total_frequencies, hex_values[i]] }
                 .sort { |r| r[0] }
                 .reject { |r| r[1].end_with?('FF') }
                 .select { |r| r[0] > 0.01 }
                 .map { |r| r[1][0..6] }
                 .map { |hex| ColorDiff::Color::RGB.new(*hex.scan(/[0-9A-Fa-f]{2}/).map { |c| c.to_i(16) }) }
                 .slice(0, quantity)
    end

    def rgb_to_hex(rgb)
      '#' + [rgb.r, rgb.g, rgb.b].map { |c| c.to_s(16).rjust(2, '0') }.join
    end
  end
end
