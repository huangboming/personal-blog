# frozen_string_literal: true

require "addressable/uri"
require "nokogiri"

module Jekyll
  module FeedContentFilters
    include Jekyll::Filters::URLFilters

    def feed_content(html, post)
      site = @context.registers[:site]
      post_url = absolute_url(post["url"])
      site_url = absolute_url("/")
      fragment = Nokogiri::HTML.fragment(html)

      fragment.css("a[href], img[src]").each do |node|
        if node.name == "img"
          source = node["src"]
          next if source.empty?

          if Addressable::URI.parse(source).absolute? || source.start_with?("//")
            node["src"] = Addressable::URI.join(site_url, source).to_s
          else
            # Chirpy applies media_subpath and CDN prefixes only when rendering the page layout.
            path = [post["media_subpath"], source].compact
              .map { |part| part.to_s.gsub(%r{\A/+|/+\z}, "") }.reject(&:empty?).join("/")
            base = site.config["cdn"].to_s.empty? ? site_url : site.config["cdn"]
            node["src"] = Addressable::URI.join(site_url, "#{base.chomp('/')}/", path).to_s
          end
        elsif !node["href"].empty?
          node["href"] = Addressable::URI.join(post_url, node["href"]).to_s
        end
      end

      fragment.to_html
    end
  end
end

Liquid::Template.register_filter(Jekyll::FeedContentFilters)
