require 'dwolla'

module Sorcery
  module Controller
    module Submodules
      module External
        module Providers
          # This module adds support for OAuth with dwolla.com.
          # When included in the 'config.providers' option, it adds a new option, 'config.dwolla'.
          # Via this new option you can configure Dwolla specific settings like your app's key and secret.
          #
          #   config.dwolla.key = <key>
          #   config.dwolla.secret = <secret>
          #   ...
          #
          module Dwolla
            def self.included(base)
              base.module_eval do
                class << self
                  attr_reader :dwolla # access to dwolla_client.
                  
                  def merge_dwolla_defaults!
                    @defaults.merge!(:@dwolla => DwollaClient)
                  end
                end
                merge_dwolla_defaults!
                update!
              end
            end
          
            module DwollaClient
              class << self
                attr_accessor :key,
                              :secret,
                              :callback_url,
                              :site,
                              :scope,
                              :auth_path,
                              :token_path,
                              :user_info_mapping
                attr_reader   :access_token

                include Protocols::Oauth2
            
                def init
                  @site           = "https://www.dwolla.com"
                  @scope          = "accountinfofull"
                  @auth_path      = "/oauth/v2/authenticate"
                  @token_path     = "/oauth/v2/token"
                  @user_info_mapping = {}
                end
                
                def has_callback?
                  true
                end
                
                def user
                	@user ||= ::Dwolla::User.me(access_token.token).fetch
                end
                
                # calculates and returns the url to which the user should be redirected,
                # to get authenticated at the external provider's site.
                def login_url(params,session)
                  self.authorize_url
                end

                # overrides oauth2#authorize_url to allow customized scope.
                def authorize_url
                  @scope = self.access_permissions.present? ? self.access_permissions.join(",") : @scope
                  super
                end

                # tries to login the user from access token
				def process_callback(params,session)
                  args = {}
                  args.merge!({:code => params[:code]}) if params[:code]
                  options = {
                    :token_url => @token_url,
                    :token_method => :post
                  }
                  @access_token = self.get_access_token(args, options)
                end
                
              end
              init
            end
            
          end
        end    
      end
    end
  end
end