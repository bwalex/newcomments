require 'net/http'

class Recaptcha
  def self.verify?(params)
    @@config ||= YAML::load(File.open('config/recaptcha.yml'))

    uri = URI(@@config['verify_url'])
    res = ::Net::HTTP.post_form(uri, {
      'privatekey' => @@config['private_key'],
      'remoteip'   => params[:remote_ip],
      'challenge'  => params[:challenge],
      'response'   => params[:response]
    })

    success, error_code = res.body.split("\n")
    return (success == 'true'), error_code
  end
end
