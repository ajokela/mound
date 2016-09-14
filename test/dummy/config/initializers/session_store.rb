# Copyright (c) 2012-2016 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's {PROJECT TITLE}.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/{REPO-NAME}

# Be sure to restart your server when you modify this file.

Dummy::Application.config.session_store :cookie_store, key: '_dummy_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Dummy::Application.config.session_store :active_record_store
