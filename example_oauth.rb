#
# Things this demo doesn't currently demonstrate:
# - rate limiting
# - client restrictions due to Litmus product / user state
# - handling the flow where a user declines authorization or signup for litmus
#

require "bundler"
Bundler.require

abort("Error starting server - OAUTH2_CLIENT_ID required") unless ENV["OAUTH2_CLIENT_ID"]
abort("Error starting server - OAUTH2_CLIENT_SECRET required") unless ENV["OAUTH2_CLIENT_SECRET"]

OmniAuth.config.failure_raise_out_environments = []
# OmniAuth 2+ defaults to only allowing POST when initiating the flow to
# minimise CSRF risks. For simplicity here, we allow GETs too.
OmniAuth.config.allowed_request_methods = [:get, :post]
use OmniAuth::Builder do
  provider :litmus, ENV['OAUTH2_CLIENT_ID'], ENV['OAUTH2_CLIENT_SECRET']
end

enable :sessions

before do
  redirect request.url.sub('http', 'https') unless request.secure?
end

get '/' do
  erb :home
end

# our resource that requires Litmus auth (as it will call out to the Litmus API)
get '/instant_api/example' do
  oauthorize! unless connected?
  message = params[:message] || 'Aloha world!'

  result = Litmus::Instant::Client.new(
    oauth_token: session[:access_token]
  ).create_email(
    { "html_text" => "<h1>#{message}</h1>" }
  )
  email_guid = JSON.parse(result.body)['email_guid']
  clients = %w(OL2019 GMAILNEW IPHONE11 THUNDERBIRDLATEST)
  previews = clients.map do |client|
    [client, Litmus::Instant.preview_image_url(email_guid, client, capture_size: 'thumb450')]
  end
  erb :instant_api_example, locals: { previews: previews }
end

get '/v3/example' do
  require 'net/http'
  require 'json'
  uri     = URI("#{ENV["LITMUS_API_HOST"]}/v3/ping/authenticated")
  token   = session[:access_token]
  request = Net::HTTP::Get.new(uri)
  request["Authorization"] = "Bearer #{token}"

  endpoint_response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do | http|
    http.request(request)
  end

  erb :v3_api_example, locals: { json: JSON.pretty_generate(JSON.parse(endpoint_response.body)) }
end

get '/sign_out' do
  # This clears our local session, but the OAuth Provider will still remember
  # that the user granted access to this application next time they connect
  session.clear
  redirect '/'
end

get '/auth/litmus/callback' do
  session[:access_token] = request.env['omniauth.auth'].credentials.token
  session[:name] = request.env['omniauth.auth'].info.name
  redirect '/'
end

get '/auth/failure' do
  erb "Auth failed: #{params[:message]}"
end

error Litmus::Instant::InactiveUserError do
  erb "The Litmus user appears to be inactive"
end

error Litmus::Instant::AuthorizationError do
  erb "The Litmus user isn't authorized to perform the required actions"
end

error Litmus::Instant::InvalidOAuthToken do
  # perhaps access has been revoked since we received the last token
  oauthorize!
end

helpers do
  def connected?
    !session[:access_token].nil?
  end

  def oauthorize!
    session[:return_to] = request.url
    # The omniauth strategy should deal with expiration and refresh for us
    redirect "/auth/litmus"
  end

  def marketing_url
    ENV["MARKETING_URL"] || "https://litmus.com/pricing/example-partner"
  end

  def app_name
    ENV["APP_NAME"] || "Example Partner App"
  end
end

__END__

@@layout
<style>body { font: 20px helvetica, arial, sans-serif; }</style>
<h1><%= app_name %></h1><hr>
<%= yield %>

@@home
<% if connected? %>
  <p>Hi <%= session[:name] %>, you are connected with Litmus OAuth</p>
  <a href="/instant_api/example">Open Instant example</a>
  <br><br>
  <a href="/v3/example">Open V3 API Example</a>
  <br><br>
  <a href="/sign_out">Sign out</a> of the Example App
  (ends session, but the app will remain authorized against the user's litmus account)
<% else %>
  You are signed out, please <a href="/auth/litmus">Connect with Litmus</a> or
  <a href="<%= marketing_url %>">Learn more</a>
<% end %>

@@instant_api_example
<p>
  Add your custom message as a parameter,
  <a href="?message=I like marmots">eg like this</a>.
</p>
<% previews.each do |client, url| %>
  <figure>
    <figcaption><%= client %></figcaption>
    <img src="<%= url %>">
  </figure>
<% end %>

@@v3_api_example
<p>
  Response from <pre><code>/v3/ping/authenticated</code></pre>
</p>
<pre><code><%= json %></code></pre>
