require 'test_helper'

module Workarea
  class SavePublishingTest < TestCase
    def test_perform_with_now
      product = create_product(active: false)

      assert(SavePublishing.new(product, activate: 'now').perform)
      assert(product.active?)
    end

    def test_perform_with_never
      product = create_product(active: false)

      assert(SavePublishing.new(product, activate: 'never').perform)
      refute(product.active?)
    end

    def test_perform_with_new_release
      product = create_product(active: false)

      publishing = SavePublishing.new(
        product,
        activate: 'new_release',
        release: { name: 'Foo' }
      )

      assert(publishing.perform)
      refute(product.active?)

      release = Release.first
      assert_equal('Foo', release.name)
      release.as_current { assert(product.reload.active?) }
    end

    def test_perform_with_existing_release
      product = create_product(active: false)
      release = create_release

      assert(SavePublishing.new(product, activate: release.id).perform)
      refute(product.active?)

      release.as_current { assert(product.reload.active?) }
    end

    def test_saving_active_by_segment
      product = create_product(active: false)
      release = create_release

      save = SavePublishing.new(
        product,
        activate: release.id,
        active_by_segment: { 'foo' => true, 'bar' => false }
      )

      assert(save.perform)

      product.reload
      refute(product.active?)
      assert(product.active_by_segment.empty?)

      release.as_current do
        assert(product.reload.active?)
        assert_equal(2, product.active_by_segment.size)
        assert(product.active_by_segment['foo'])
        refute(product.active_by_segment['bar'])
      end
    end
  end
end
