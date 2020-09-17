set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'

# Use the RedCarpet Markdown engine
set :markdown_engine, :redcarpet
set :markdown, fenced_code_blocks: true

set :relative_links, true

# Use relative URLs
activate :relative_assets

# Use syntax highlighting
activate :syntax

# Build-specific configuration
configure :build do
  activate :asset_hash
  activate :minify_css
  activate :minify_javascript
end

activate :deploy do |deploy|
  deploy.remote = 'origin'
  deploy.deploy_method = :git
  deploy.branch = 'gh-pages'
end
