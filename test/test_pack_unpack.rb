require 'test/unit'
require "lib/minus5_daemon/zmq_helper.rb"

class String
  def copy_out_string
    self
  end
end

class TestPackUnpack < Test::Unit::TestCase

  def pack_unpack(action, headers, body)
    h, b = Minus5::Service::ZmqProxy.pack_msg(action, headers, body)
    Minus5::Service::ZmqProxy.unpack_msg(["", "" , "", h, b])
  end

  def test_pack_unpack_string
    a1 = "action"
    h1 = {:header => 1}
    b1 = "iso medo u ducan"
    a2, h2, b2 = pack_unpack a1, h1, b1
    assert_equal a1, a2
    assert_equal h2.header, h1[:header]
    assert_equal h2.content_type, "string"
    assert_equal b1, b2
  end

  def test_pack_unpack_hash
    a1 = "action"
    b1 = {:pero => "zdero"}
    a2, h2, b2 = pack_unpack a1, {}, b1
    assert_equal h2.content_type, "json"
    assert_equal b1[:pero], b2["pero"]
  end

  def test_pack_unpack_time
    a1 = "action"
    b1 = Time.now
    a2, h2, b2 = pack_unpack a1, {}, b1
    assert_equal h2.content_type, "json/packed"
    assert_equal b1.to_s, b2
  end  
  
end
