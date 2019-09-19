require 'test_helper'

module Workarea
  class SegmentTest < TestCase
    def test_find_qualifying
      one = create_segment(rules: [Segment::Rules::Orders.new(minimum: 1)])
      two = create_segment(rules: [Segment::Rules::Orders.new(minimum: 2)])
      three = create_segment(rules: [Segment::Rules::Orders.new(minimum: 3)])

      metrics = Metrics::User.create!(id: 'bcrouse@workarea.com')

      visit = create_visit(email: 'bcrouse@workarea.com')
      assert(Segment.find_qualifying(visit).empty?)

      metrics.update_attributes!(orders: 1)
      visit = create_visit(email: 'bcrouse@workarea.com')
      assert_equal([one], Segment.find_qualifying(visit))

      metrics.update_attributes!(orders: 2)
      visit = create_visit(email: 'bcrouse@workarea.com')
      assert_equal([one, two], Segment.find_qualifying(visit))

      metrics.update_attributes!(orders: 3)
      visit = create_visit(email: 'bcrouse@workarea.com')
      assert_equal([one, two, three], Segment.find_qualifying(visit))
    end

    def test_apply
      assert_equal([], Segment.applied)

      segment = create_segment
      Segment.apply(segment) { assert_equal([segment], Segment.applied) }
      assert_equal([], Segment.applied)

      Segment.apply([segment]) { assert_equal([segment], Segment.applied) }
      assert_equal([], Segment.applied)

      assert_raises { Segment.apply(segment) { raise 'foo' } }
      assert_equal([], Segment.applied)
    end

    def test_apply_returns_the_value_from_the_block
      segment = create_segment
      result = Segment.apply(segment) { 'foo' }
      assert_equal('foo', result)
    end

    def test_qualifies
      segment = create_segment(
        rules: [
          Segment::Rules::Orders.new(minimum: 2),
          Segment::Rules::Sessions.new(minimum: 5)
        ]
      )

      metrics = Metrics::User.create!(id: 'bcrouse@workarea.com')

      visit = create_visit(email: 'bcrouse@workarea.com')
      refute(segment.qualifies?(visit))

      metrics.update_attributes!(orders: 2)
      visit = create_visit(email: 'bcrouse@workarea.com')
      refute(segment.qualifies?(visit))

      visit = create_visit(email: 'bcrouse@workarea.com', sessions: 2)
      refute(segment.qualifies?(visit))

      visit = create_visit(email: 'bcrouse@workarea.com', sessions: 5)
      assert(segment.qualifies?(visit))
    end
  end
end
