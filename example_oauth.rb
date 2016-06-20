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

use OmniAuth::Builder do
  provider :litmus, ENV['OAUTH2_CLIENT_ID'], ENV['OAUTH2_CLIENT_SECRET']
end

enable :sessions

helpers do
  def connected?
    !session[:access_token].nil?
  end

  def oauthorize!
    session[:return_to] = request.url
    # The omniauth strategy should deal with expiration and refresh for us
    redirect "/auth/litmus"
  end
end

get '/' do
  erb :home
end

# our resource that requires Litmus auth (as it will call out to the Litmus API)
get '/example' do
  oauthorize! unless connected?
  message = params[:message] || 'Aloha world!'

  result = Litmus::Instant.create_email(
    { 'plain_text' => message },
    token: session[:access_token]
  )
  email_guid = JSON.parse(result.body)['email_guid']
  clients = %w(OL2000 GMAILNEW IPHONE6 THUNDERBIRDLATEST)
  previews = clients.map do |client|
    [client, Litmus::Instant.preview_image_url(email_guid, client, capture_size: 'thumb450')]
  end
  erb :example, locals: { previews: previews }
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
  "Auth failed #{params[:message]}"
end

error Litmus::Instant::InactiveUserError do
  "The Litmus user appears to be inactive"
end

error Litmus::Instant::AuthorizationError do
  "The Litmus user isn't authorized to perform the required actions"
end

error Litmus::Instant::InvalidOAuthToken do
  # perhaps access has been revoked since we received the last token
  oauthorize!
end

__END__

@@home
<h1>Example Partner App</h1>
<% if connected? %>
  <p>Hi <%= session[:name] %>, you are connected with Litmus OAuth</p>
  <a href="/example">Open Instant example</a>
  <br><br>
  <a href="/sign_out">Sign out</a> of the Example App
  (ends session, but the app will remain authorized against the user's litmus account)
<% else %>
  You are signed out, please <a href="/auth/litmus">Connect with Litmus</a> or
  <a href="https://litmus.com#cobranded-landing">Learn more</a>
<% end %>

@@example
<h1>Example Partner App</h1>
<p>
  Add your custom message as a parameter,
  <a href="?message=I like marmots">eg like this</a>.
<p>
<% previews.each do |client, url| %>
  <figure>
    <figcaption><%= client %></figcaption>
    <img src="<%= url %>">
  </figure>
<% end %>
