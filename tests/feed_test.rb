# frozen_string_literal: true

require "jekyll"
require "time"
require_relative "../_plugins/feed-content"

def assert(condition, message)
  raise message unless condition
end

def render_content(html, media_subpath: "/assets/images/example/", cdn: nil)
  site = Struct.new(:config, :filter_cache).new(
    { "url" => "https://example.test", "baseurl" => "/blog", "cdn" => cdn }, {}
  )
  Liquid::Template.parse("{{ html | feed_content: post }}").render!(
    { "html" => html, "post" => { "url" => "/posts/example/", "media_subpath" => media_subpath } },
    registers: { site: site }
  )
end

sample = <<~HTML
  <a href="/blog/posts/other/?a=1&amp;b=2">Root link</a>
  <a href="../other/#section">Relative link</a>
  <a href="#脚注">Fragment</a>
  <a href="mailto:reader@example.test">Email</a>
  <img src="1.png" alt="A &amp; B">
  <img src="https://external.test/image.png">
  <img src="//external.test/image.png">
  <img src="data:image/png;base64,AAAA">
  <pre><code>&lt;a href="/unchanged"&gt;A &amp; B&lt;/a&gt;\n  indented</code></pre>
HTML
fragment = Nokogiri::HTML.fragment(render_content(sample))
expected_links = [
  "https://example.test/blog/posts/other/?a=1&b=2",
  "https://example.test/blog/posts/other/#section",
  "https://example.test/blog/posts/example/#脚注",
  "mailto:reader@example.test"
].map { |url| Addressable::URI.parse(url).normalize }
actual_links = fragment.css("a").map { |node| Addressable::URI.parse(node["href"]).normalize }
assert(actual_links == expected_links, "Feed links must resolve against the article URL without double-encoding queries")
assert(fragment.css("img").map { |node| node["src"] } == [
  "https://example.test/blog/assets/images/example/1.png",
  "https://external.test/image.png", "https://external.test/image.png", "data:image/png;base64,AAAA"
], "Feed images must support media_subpath, baseurl, external URLs, and data URIs")
assert(fragment.at_css("pre code").text == "<a href=\"/unchanged\">A & B</a>\n  indented",
  "HTML examples and code whitespace must remain unchanged")
cdn_image = Nokogiri::HTML.fragment(render_content('<img src="1.png">', cdn: "https://cdn.test/media/"))
assert(cdn_image.at_css("img")["src"] == "https://cdn.test/media/assets/images/example/1.png",
  "Feed images must retain the CDN path prefix")
[nil, ""].each do |subpath|
  image = Nokogiri::HTML.fragment(render_content('<img src="1.png">', media_subpath: subpath))
  assert(image.at_css("img")["src"] == "https://example.test/blog/1.png", "Empty media_subpath must retain baseurl")
end

template = File.read(File.join(__dir__, "../assets/feed.xml")).split(/^---\s*$\n?/, 3).last
sample_posts = Array.new(22) do |index|
  {
    "url" => "/posts/example-#{index}/", "title" => "<Title> & #{index}",
    "date" => Time.utc(2026, 1, 22) - index * 86_400, "categories" => ["A & B"],
    "description" => "Summary & #{index}", "content" => "<p>Full &amp; body #{index}</p><pre><code>&lt;tag&gt;</code></pre>"
  }
end
sample_posts.first["author"] = "guest"
site = Struct.new(:config, :filter_cache).new({ "url" => "https://example.test", "baseurl" => "/blog" }, {})
payload = {
  "site" => {
    "title" => "Blog & <Name>", "description" => "Description & details", "lang" => "zh-CN", "time" => Time.utc(2026),
    "posts" => sample_posts, "author" => { "name" => "Default & Author", "url" => "https://example.test/about/" },
    "data" => { "authors" => { "guest" => { "name" => "Guest & Author", "url" => "https://guest.test/" } } }
  },
  "page" => { "url" => "/feed.xml" }, "jekyll" => { "version" => Jekyll::VERSION }
}
rendered = Liquid::Template.parse(template).render!(payload, registers: { site: site })
sample_feed = Nokogiri::XML(rendered) { |config| config.strict.nonet }
ns = { "a" => "http://www.w3.org/2005/Atom" }
sample_entries = sample_feed.xpath("/a:feed/a:entry", ns)
assert(sample_entries.size == 20, "Feed must cap entries at 20 when more posts exist")
assert(sample_feed.at_xpath("/a:feed/a:title", ns).text == "Blog & <Name>", "Feed title must be escaped exactly once")
assert(sample_entries.first.at_xpath("a:title", ns).text == "<Title> & 0", "Entry title must be escaped exactly once")
assert(sample_entries.first.at_xpath("a:category", ns)["term"] == "A & B", "Category attributes must be XML-safe")
assert(sample_entries.first.at_xpath("a:author/a:name", ns).text == "Guest & Author", "Named authors must resolve from site data")
assert(sample_entries[1].at_xpath("a:author/a:name", ns).text == "Default & Author", "Entries must inherit the default author")
sample_body = Nokogiri::HTML.fragment(sample_entries.first.at_xpath("a:content", ns).text)
assert(sample_body.at_css("p").text == "Full & body 0" && sample_body.at_css("pre code").text == "<tag>",
  "Embedded HTML entities and code examples must survive the Atom round trip")

puts "Feed logic checks passed: URL handling, XML escaping, full content, authors, and the 20-entry limit"
