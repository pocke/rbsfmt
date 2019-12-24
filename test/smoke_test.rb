require 'test_helper'

class SmokeTest < Minitest::Test
  def test_smoke
    Pathname.glob('smoke/*.rbs').each do |path|
      out = StringIO.new
      content = path.read
      Rbsfmt::Runner.new(content, out: out).run

      assert_equal content, out.string
    end
  end
end
