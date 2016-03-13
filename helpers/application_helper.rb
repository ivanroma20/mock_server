
module ApplicationHelper

  def h(text)
    Rack::Utils.escape_html(text)
  end
  #
  # The main processing function that server the mock responses
  # Read the model for the given url in a test environment and serve it as a HTTP response
  # as specified in the mock with correct headers and status code.
  #
  # @param [String] url, The URL that is being mocked.
  # @return [Hash] response hash with keys :mock_http_status, :mock_data_response_headers, :mock_data_response [,:error]
  #

  def process_url(url, env=ENV['TEST_ENV'])
    return_data={}
    data = Mockdata.where(mock_request_url: url, mock_environment: env)
    if data.any?
      row = data.first
      return_data[:mock_http_status] = row[:mock_http_status]
      return_data[:mock_data_response] = row[:mock_data_response]
      return_data[:mock_data_response_headers] = build_headers row[:mock_data_response_headers]

      return_data[:mock_content_type] = row[:mock_content_type]
      row.mock_served_times = row.mock_served_times + 1
      row.save!
    else
      return_data[:error] = "Not Found"
    end
    return return_data
  end

  #
  # Search for mock data either by name OR URL. Options key name should match the column name
  # @param [Hash] options with key :mock_name or :mock_request_url
  #
  def search_mock_data(options)
    # data = Mockdata.where(mock_name: options[:mock_name])
    data = Mockdata.where("mock_name LIKE ?", "%#{options[:mock_name]}%")
    if data.any?
      return data
    else
      return nil
    end
  end

  #
  #
  #
  def flash_messages
    session[:errors]
  end

  #
  # Build headers hash
  # @param [String] the headers string
  # @return [Hash] The headers hash
  #

  def build_headers(headers_string)
    headers_hash = {}
    headers_array = headers_string.split(/\r\n/)
    headers_array.each do |header_row|
      k,v = header_row.split(ENV['HEADER_DELIMITER'])
      headers_hash[k] = v
    end
    return headers_hash
  end

  #
  # Extract the HTTParty response for cloning the mock data set response hash to include all table columns.
  # The clone will only provide the body and the headers, rest set to nil. Assumes a valid HTTP response with success
  #
  def extract_clone_response(response,url,mock_name)

    mock_data = ClonedData.new
    mock_data.mock_name = mock_name
    mock_data.mock_http_status = response.code
    mock_data.mock_state = true
    mock_data.mock_environment = ENV['TEST_ENV']
    mock_data.mock_content_type = ENV['DEFAULT_CONTENT_TYPE']
    mock_data.mock_request_url = url
    hdr_string = 'X-Mock'+ENV['HEADER_DELIMITER']+'True'
    response.headers.each do |header,hdr_value|
      hdr_string = hdr_string + "\r\n" + header + ENV['HEADER_DELIMITER'] + hdr_value
    end
    mock_data.mock_data_response_headers = hdr_string
    mock_data.mock_data_response = response.body
    return mock_data
  end

  #
  # JSON Validator
  #
  def valid_json?(json)
    begin
      JSON.parse(json)
      return true
    rescue JSON::ParserError => e
      return false
    end
  end

  #
  #
  #
  def process_batch_clone_request(params)

  end

end
