require 'base64'
require 'json'
require 'net/http'
require 'uri'
require 'cgi'

module Mixpanel
  class ActivityLogger
    BASE_ENDPOINT   = 'http://api.mixpanel.com'
    TRACK_ENDPOINT  = "#{BASE_ENDPOINT}/track/"
    ENGAGE_ENDPOINT = "#{BASE_ENDPOINT}/engage/"


    def initialize( token )
      @token  = token
    end


    # EVENTS
    #
    ###########################################################################

    # Record an event

    # Required properties
    #
    # namespace - event identifier
    # user_id - any string that uniquely can identify a user.

    # Optional properties
    #
    # time - time at which the event occured, it must be a unix timestamp.
    # ip - raw string IP Address (e.g. "127.0.0.1") that you pass to our API.
    # mp_name_tag - set a namespace for a given user for our streams feature.
    #               (only supported for streams).
    #
    def track_event(props={})
      raise "Missing required attribute: namespace" if props[:namespace].nil?
      raise "Missing required attribute: user_id" if props[:user_id].nil?

      namespace = props.delete :namespace
      props[:token] = @token
      props[:time]  = props.delete :created_at unless props[:created_at].nil?

      encoded_props = encode({event: namespace, properties: props})
      send_request("#{TRACK_ENDPOINT}?#{encoded_props}")
    end


    # PEOPLE
    #
    ###########################################################################

    # Sets the user attributes

    # Required properties
    #
    # user_id - any string that uniquely can identify a user.

    # Optional properties
    #
    # ip - The IP of the user, which we automatically parse into Country/Region/City. If you don't want to set these properties, set it to 0 or we will collect the IP of your server. Place this outside of the $set dictionary.
    # ignore_time - When set to "true", this property bypasses the automatic re-setting of the "Last Seen" date property. Defaults to false.
    # email - The email of the user. This is used if you wish to send emails to your users through People Analytics.
    # first_name, $last_name - The first and last name of your user.
    # created - When your user created their account.
    # username - The username of a given user
    # any other trackable people property to track
    #
    def set_user(props={})
      send_people_request("$set", props)
    end


    # set a user attribute, only if it is not currently set.

    # Required properties
    #
    # user_id - any string that uniquely can identify a user.

    # Optional properties
    #
    # ip - The IP of the user, which we automatically parse into Country/Region/City. If you don't want to set these properties, set it to 0 or we will collect the IP of your server. Place this outside of the $set dictionary.
    # ignore_time - When set to "true", this property bypasses the automatic re-setting of the "Last Seen" date property. Defaults to false.
    # email - The email of the user. This is used if you wish to send emails to your users through People Analytics.
    # first_name, $last_name - The first and last name of your user.
    # created - When your user created their account.
    # username - The username of a given user
    # any other trackable people property to track
    #
    def set_one()
      send_people_request("$set_once", props)
    end


    # increment numeric attributes.

    # Required properties
    #
    # user_id - any string that uniquely can identify a user.

    # Optional properties
    #
    # ip - The IP of the user, which we automatically parse into Country/Region/City. If you don't want to set these properties, set it to 0 or we will collect the IP of your server. Place this outside of the $set dictionary.
    # any numeric attribute
    #
    def add()
      send_people_request("$add", props)
    end


    # Record that you have charged the current user a certain amount of money.
    #
    def append()
      raise "Not implemented: mixpanel's append"
    end


    protected

    BASE_PROPS   = [:ip, :user_id]
    PEOPLE_PROPS = [:email, :first_name, :last_name, :created, :username]

    def send_people_request(action, props={})
      raise "Missing required attribute: user_id" if props[:user_id].nil?

      props = props.dup
      data  = {}

      # split properties from people and from the base service
      BASE_PROPS.each {|k| data["$#{k}"] = props.delete(k) unless props[k].nil? }

      # reformat keys prepending an $. for some insane reason this is a requirement
      PEOPLE_PROPS.each {|k| props["$#{k}"] = props.delete(k) unless props[k].nil? }

      data[action]   = props
      data["$ip"]    = 0 if data["$ip"].nil? # do not track server ip if nil
      data["$token"] = @token

      send_request("#{ENGAGE_ENDPOINT}?#{encode(data)}")
    end

    # Encodes request params accoding to Mixpanel specs
    #
    def encode(data, params={})
      encoded = Base64::encode64(data.to_json).gsub(/\s/, '')

      param_strings = []

      params[:data] = encoded
      params.each_pair {|key,val|
        param_strings << "#{key}=#{CGI.escape(val.to_s)}"
      }
      return "#{param_strings.join('&')}"
    end


    # Send request to Mixpanel
    #
    def send_request(url)
      uri = URI.parse url
      req = Net::HTTP::Post.new(uri.path)
      req.body = uri.query
      res = Net::HTTP.start(uri.host, uri.port) {|http|
        http.request(req)
      }

      raise "Mixpanel error: #{url}" if !res.is_a? Net::HTTPSuccess
    end
  end
end
