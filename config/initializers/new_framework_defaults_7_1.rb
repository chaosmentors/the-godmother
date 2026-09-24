# Be sure to restart your server when you modify this file.
#
# config/application.rb has advanced past 7.1. Everything the 7.1 defaults
# change is adopted EXCEPT the two flags below, which are held at 7.0 behaviour
# on purpose.
#
# Why: this app uses the default cookie session store and session-based auth.
# Both flags change the on-the-wire format of signed/encrypted messages, and
# cookies written in the new format cannot be read by the old code. Adopting
# them is therefore a one-way door — a rollback after deploying would log every
# logged-in user out, which is the worst thing that can happen mid-incident.
#
# Removal plan: leave these pinned for one week of production soak on 7.1
# defaults. Once a rollback is off the table, delete this file in its own
# one-line commit (and coordinate with any secret_key_base rotation, since that
# invalidates sessions too).
#
# Note: Rails 7.2 does NOT move these further — `load_defaults "7.2"` leaves
# message_serializer at :json_allow_marshal — so this one pin covers both rungs.
# Verified against railties-7.2.3.2 configuration.rb.

# 7.1 default is :json_allow_marshal. 7.0 behaviour is :marshal.
Rails.application.config.active_support.message_serializer = :marshal

# 7.1 default is true. Serializing metadata with the message serializer changes
# the message format; older Rails cannot read it.
Rails.application.config.active_support.use_message_serializer_for_metadata = false
