module Rhoconnect
  # Constants
  #
  CURRENT_REQUEST = 'CURRENT_REQUEST'.freeze
  CURRENT_APP = 'CURRENT_APP'.freeze
  CURRENT_USER = 'CURRENT_USER'.freeze
  CURRENT_SOURCE = 'CURRENT_SOURCE'.freeze
  CURRENT_CLIENT = 'CURRENT_CLIENT'.freeze
  QUERY_RES = 'QUERY_RES'.freeze

  UNKNOWN_CLIENT = "Unknown client".freeze
  UNKNOWN_SOURCE = "Unknown source".freeze

  # TODO : Remove in Rhoconnect 4.0
  SYNC_VERSION = 3
  
  # header names, in the form of server's HTTP variables
  # X-RhoConnect-API-TOKEN
  API_TOKEN_HEADER = 'HTTP_X_RHOCONNECT_API_TOKEN'.freeze
  # X-RhoConnect-CLIENT-ID
  CLIENT_ID_HEADER = 'HTTP_X_RHOCONNECT_CLIENT_ID'.freeze
  # X-RhoConnect-PAGE-TOKEN
  PAGE_TOKEN_HEADER = 'X-Rhoconnect-PAGE-TOKEN'
  # X-RhoConnect-PAGE-OBJECT-COUNT
  PAGE_OBJECT_COUNT_HEADER = 'X-Rhoconnect-PAGE-OBJECT-COUNT'
end