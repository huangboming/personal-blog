# frozen_string_literal: true

require "addressable/uri"
require "json"
require "nokogiri"
require "time"

def assert(condition, message)
  raise message unless condition
end

site_dir = File.expand_path(ARGV.fetch(0, "_site"))
assert(!File.exist?(File.join(site_dir, "tests")), "Test sources must not be published")
feed = Nokogiri::XML(File.read(File.join(site_dir, "feed.xml"))) { |config| config.strict.nonet }
ns = { "a" => "http://www.w3.org/2005/Atom" }
root_url = feed.at_xpath("/a:feed/a:id", ns).text
root_uri = Addressable::URI.parse(root_url)
entries = feed.xpath("/a:feed/a:entry", ns)
authors_by_url = Dir[File.join(site_dir, "posts/*/index.html")].to_h do |path|
  html = Nokogiri::HTML(File.read(path))
  data = html.css('script[type="application/ld+json"]').map { |node| JSON.parse(node.text) }
  article = data.find { |item| item["@type"] == "BlogPosting" }
  assert(article, "Missing BlogPosting data: #{path}")
  author = article["author"]
  assert(author && author["@type"] == "Person" && !author["name"].to_s.empty?, "Missing author: #{path}")
  assert(author["url"] && Addressable::URI.parse(author["url"]).absolute?, "Missing absolute author URL: #{path}")
  canonical = html.at_css('link[rel="canonical"]')["href"]
  [canonical, author]
end
assert(!authors_by_url.empty?, "No generated articles found in #{site_dir}")
assert(entries.size == [authors_by_url.size, 20].min, "Feed must contain the latest 20 published articles, or all if fewer")
ids = entries.map { |entry| entry.at_xpath("a:id", ns).text }
assert(ids.uniq.size == ids.size, "Feed entry IDs must be unique")
published = entries.map { |entry| Time.iso8601(entry.at_xpath("a:published", ns).text) }
assert(published == published.sort.reverse, "Feed entries must be newest first")

entries.each do |entry|
  id = entry.at_xpath("a:id", ns).text
  author = authors_by_url.fetch(id) { raise "Feed ID must remain the article canonical URL: #{id}" }
  assert(entry.at_xpath('a:link[@rel="alternate"]', ns)["href"] == id, "Entry link differs from canonical: #{id}")
  assert(entry.at_xpath("a:author/a:name", ns).text == author["name"], "Feed and SEO authors differ: #{id}")
  content = entry.at_xpath("a:content", ns)
  assert(content["type"] == "html" && !content["src"], "Feed must embed HTML rather than reference an external body: #{id}")
  body = Nokogiri::HTML.fragment(content.text)
  assert(!body.text.strip.empty?, "Feed content must not be empty: #{id}")
  Time.iso8601(entry.at_xpath("a:updated", ns).text)

  body.css("a[href], img[src]").each do |node|
    value = node[node.name == "img" ? "src" : "href"]
    next if value.empty?

    uri = Addressable::URI.parse(value)
    assert(uri.absolute?, "Relative URL in feed: #{value}")
    next unless node.name == "img" && uri.host == root_uri.host

    path = Addressable::URI.unencode_component(uri.path).delete_prefix(root_uri.path.chomp("/"))
    assert(File.file?(File.join(site_dir, path.delete_prefix("/"))), "Missing feed image: #{value}")
  end
end

home = Nokogiri::HTML(File.read(File.join(site_dir, "index.html")))
links = home.css('head link[rel="alternate"][type="application/atom+xml"]')
assert(links.size == 1 && links.first["href"] == root_url + "feed.xml", "Missing or duplicate Feed auto-discovery link")
assert(feed.at_xpath('/a:feed/a:link[@rel="self"]', ns)["href"] == links.first["href"], "Feed self link differs from discovery URL")
puts "Site metadata checks passed: #{authors_by_url.size} article authors, #{entries.size} Feed entries, URLs, and discovery"
