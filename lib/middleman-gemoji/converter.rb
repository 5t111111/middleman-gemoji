require 'gemoji'

module Middleman
  module Gemoji
    class Converter
      attr_reader :app, :options, :base_path

      def initialize(app, options)
        if !app.is_a?(Middleman::Application)
          raise "app is not Middleman::Application"
        end

        @app = app
        @options = options
        set_base_path
      end

      def convert(content)
        return content if content.blank?

        if has_body?(content)
          emojify_inner_body(content)
        else
          emojify(content)
        end
      end

      def emojify(content)
        content.to_str.gsub(/:([\w+-]+):/) do |match|
          if (emoji = Emoji.find_by_alias(Regexp.last_match[1]))
            %(<g-emoji alias="#{Regexp.last_match[1]}" ) + \
              fallback_src(emoji.image_filename) + ' ' + \
              fallback_img_size + ' ' + \
              %(ios-version="6.0">#{emoji.raw}</g-emoji>)
          else
            match
          end
        end
      end

      # emojify only in the body tag
      def emojify_inner_body(content)
        pattern = /<body.+?>(.+?)<\/body>/m
        content.to_str.gsub(pattern) do |html|
          emojify(html).gsub(pattern, '\1')
        end
      end

      def has_body?(content)
        !(/<body.+?>.+?<\/body>/m =~ content.to_str).nil?
      end

      def fallback_src(path)
        %(fallback-src=#{File.join(@base_path, path)})
      end

      def fallback_img_size
        @options[:size] ? %(fallback-img-size width="#{@options[:size]}" height="#{@options[:size]}") : ''
      end

      def style
        %(style="#{@options[:style]}") if @options[:style]
      end

      def emoji_file_exist?
        Dir.exist?(
          File.join(@app.root, @app.config.source, @options[:emoji_dir], 'unicode')
        )
      end

      def set_base_path
        @base_path = 'https://assets-cdn.github.com/images/icons/emoji/'
        if emoji_file_exist?
          if /^http/ =~ @app.config[:http_prefix]
            @base_path = File.join(app.config[:http_prefix], options[:emoji_dir])
          else
            @base_path = File.join('/', app.config[:http_prefix], options[:emoji_dir])
          end
        end
      end

    end
  end
end
