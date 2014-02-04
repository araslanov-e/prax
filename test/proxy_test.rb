require 'test_helper'
require 'open3'
require 'net/http'

describe "Proxy" do
  it "proxies to rack applications" do
    assert_equal "example", Net::HTTP.get(URI('http://example.dev:20557/'))
    assert_equal "example", Net::HTTP.get(URI('http://www.example.dev:20557/'))

    assert_equal "app1.example", Net::HTTP.get(URI('http://app1.example.dev:20557/'))
    assert_equal "app1.example", Net::HTTP.get(URI('http://www.app1.example.dev:20557/'))

    assert_equal "app2.example", Net::HTTP.get(URI('http://app2.example.dev:20557/'))
    assert_equal "app2.example", Net::HTTP.get(URI('http://w3.app2.example.dev:20557/'))
  end

  it "supports xip.io" do
    assert_equal "example", Net::HTTP.get(URI('http://example.127.0.0.1.xip.io:20557/'))
    assert_equal "example", Net::HTTP.get(URI('http://w1.example.127.0.0.1.xip.io:20557/'))

    assert_equal "app1.example", Net::HTTP.get(URI('http://app1.example.127.0.0.1.xip.io:20557/'))
    assert_equal "app2.example", Net::HTTP.get(URI('http://w3.app2.example.127.0.0.1.xip.io:20557/'))
  end

  it "serves public files" do
    assert_equal "my file contents\n", Net::HTTP.get(URI('http://example.dev:20557/file.txt'))
    assert_equal "my file contents\n", Net::HTTP.get(URI('http://example.127.0.0.1.xip.io:20557/file.txt'))
  end

  it "forwards to a given port" do
    ready = false
    response = "TCPServer: OK\n"

    t1 = Thread.new do
      server = TCPServer.new('localhost', 3123)
      ready = true
      loop do
        begin
          socket = server.accept_nonblock
          socket.write "HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Length: #{response.size}\r\n\r\n#{response}"
          socket.flush
          break
        rescue Errno::EAGAIN
          Thread.pass
        end
      end
      server.close
    end

    until ready
      sleep(0.01)
      Thread.pass
    end

    assert_equal response, Net::HTTP.get(URI('http://forward.dev:20557/'))
    t1.join
  end
end