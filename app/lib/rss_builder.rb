# frozen_string_literal: true

class RSSBuilder
  def self.build
    new.tap do |builder|
      yield builder
    end.to_xml
  end

  class ItemBuilder
    def initialize
      @root = Ox::Element.new('item')
    end

    def title(str)
      @root << (Ox::Element.new('title') << str)
    end

    def link(str)
      @root << Ox::Element.new('guid').tap do |guid|
        guid['isPermalink'] = 'true'
        guid << str
      end

      @root << (Ox::Element.new('link') << str)
    end

    def pub_date(date)
      @root << (Ox::Element.new('pubDate') << date.to_formatted_s(:rfc822))
    end

    def description(str)
      @root << (Ox::Element.new('description') << str)
    end

    def category(str)
      @root << (Ox::Element.new('category') << str)
    end

    def enclosure(url, type, size)
      @root << Ox::Element.new('enclosure').tap do |enclosure|
        enclosure['url']    = url
        enclosure['length'] = size
        enclosure['type']   = type
      end
    end

    def media_group
      @root << MediaGroupBuilder.new.tap do |group|
        yield group
      end.to_element
    end

    def to_element
      @root
    end
  end

  class MediaGroupBuilder
    def initialize
      @root = Ox::Element.new('media:group')
    end

    def content(url, type, size)
      @root << Ox::Element.new('media:content').tap do |content|
        content['url']      = url
        content['type']     = type
        content['fileSize'] = size
      end
    end

    def rating(val)
      @root << Ox::Element.new('media:rating').tap do |rating|
        rating['scheme'] = 'urn:simple'
        rating << val
      end
    end

    def description(val)
      @root << Ox::Element.new('media:description').tap do |description|
        description['type'] = 'plain'
        description << val
      end
    end

    def to_element
      @root
    end
  end

  def initialize
    @root = Ox::Element.new('channel')
  end

  def title(str)
    @root << (Ox::Element.new('title') << str)
  end

  def link(str)
    @root << (Ox::Element.new('link') << str)
  end

  def last_build_date(date)
    @root << (Ox::Element.new('lastBuildDate') << date.to_formatted_s(:rfc822))
  end

  def image(str)
    @root << Ox::Element.new('image').tap do |image|
      image << (Ox::Element.new('url') << str)
      image << (Ox::Element.new('title') << '')
      image << (Ox::Element.new('link') << '')
    end

    @root << (Ox::Element.new('webfeeds:icon') << str)
  end

  def cover(str)
    @root << Ox::Element.new('webfeeds:cover').tap do |cover|
      cover['image'] = str
    end
  end

  def logo(str)
    @root << (Ox::Element.new('webfeeds:logo') << str)
  end

  def accent_color(str)
    @root << (Ox::Element.new('webfeeds:accentColor') << str)
  end

  def description(str)
    @root << (Ox::Element.new('description') << str)
  end

  def item
    @root << ItemBuilder.new.tap do |item|
      yield item
    end.to_element
  end

  def to_xml
    ('<?xml version="1.0" encoding="UTF-8"?>' + Ox.dump(wrap_in_document, effort: :tolerant)).force_encoding('UTF-8')
  end

  private

  def wrap_in_document
    Ox::Document.new(version: '1.0').tap do |document|
      document << Ox::Element.new('rss').tap do |rss|
        rss['version']        = '2.0'
        rss['xmlns:webfeeds'] = 'http://webfeeds.org/rss/1.0'
        rss['xmlns:media']    = 'http://search.yahoo.com/mrss/'

        rss << @root
      end
    end
  end
end
