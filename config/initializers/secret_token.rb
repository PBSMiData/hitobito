# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Be sure to restart your server when you modify this file.

def initialize_secret
  # Only generate token based if we're running on OPENSHIFT
  secret = ENV['OPENSHIFT_SECRET_TOKEN']
  if secret
    # Create seed for random function from secret and name
    seed = [secret, 'f2511b259f4743606a45be8cbbd42'].join('-')
    # Generate hash from seed
    hash = Digest::SHA512.hexdigest(seed)
    hash[0, 128]
  else
    ENV['SECRET_KEY_BASE'] || ENV['RAILS_SECRET_TOKEN'] ||
      '026a97227d5e4cdf52470310b0f2511b259f4743606a45be8cbbd42ee48a004ee0d71de819138ba36b6526c58cd7811f5ca58f2f1e006835f57c551d6192f974'
  end
end

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
Hitobito::Application.config.secret_key_base = initialize_secret
