# frozen_string_literal: true
require 'test_helper'
require 'project_types/extension/extension_test_helpers'
require 'base64'
require 'pathname'

module Extension
  module Features
    class ArgoTest < MiniTest::Test
      include TestHelpers::FakeUI
      include ExtensionTestHelpers::Stubs::ArgoScript

      def setup
        super
        ShopifyCli::ProjectType.load_type(:extension)

        @git_template = 'https://www.github.com/fake_template.git'
        @argo = Argo.new(
          setup: Features::ArgoSetup.new(git_template: @git_template),
          renderer_package: '@fake_renderer_package'
        )
        @identifier = 'FAKE_ARGO_TYPE'
        @directory = 'fake_directory'
      end

      def test_config_aborts_with_error_if_script_file_doesnt_exist
        @argo.stubs(:extract_argo_renderer_version).returns('0.0.1')
        error = assert_raises ShopifyCli::Abort do
          @argo.config(@context)
        end

        assert error.message.include?(@context.message('features.argo.missing_file_error'))
      end

      def test_config_aborts_with_error_if_script_serialization_fails
        @argo.stubs(:extract_argo_renderer_version).returns('0.0.1')
        File.stubs(:exist?).returns(true)
        Base64.stubs(:strict_encode64).raises(IOError)

        error = assert_raises(ShopifyCli::Abort) { @argo.config(@context) }
        assert error.message.include?(@context.message('features.argo.script_prepare_error'))
      end

      def test_config_aborts_with_error_if_file_read_fails
        @argo.stubs(:extract_argo_renderer_version).returns('0.0.1')
        File.stubs(:exist?).returns(true)
        File.any_instance.stubs(:read).raises(IOError)

        error = assert_raises(ShopifyCli::Abort) { @argo.config(@context) }
        assert error.message.include?(@context.message('features.argo.script_prepare_error'))
      end

      def test_config_encodes_script_into_context_if_it_exists
        with_stubbed_script(@context, Argo::SCRIPT_PATH) do
          @argo.stubs(:extract_argo_renderer_version).returns('0.0.1')
          config = @argo.config(@context)

          assert_includes config.keys, :serialized_script
          assert_equal Base64.strict_encode64(TEMPLATE_SCRIPT.chomp), config[:serialized_script]
        end
      end

      def test_admin_method_returns_an_argo_extension_with_the_subscription_management_template
        git_admin_template = 'https://github.com/Shopify/argo-admin-template.git'
        argo = Argo.admin
        assert_equal(argo.setup.git_template, git_admin_template)
      end

      def test_checkout_method_returns_an_argo_extension_with_the_checkout_post_purchase_template
        git_checkout_template = 'https://github.com/Shopify/argo-checkout-template.git'
        argo = Argo.checkout
        assert_equal(argo.setup.git_template, git_checkout_template)
      end

      def test_version_renderer_returns_argo_admin_renderer_package_version
        result = '{
             "name": "fake-extension-template",
             "version": "0.1.0",
             "dependencies": {
               "@fake_renderer_package": {
                 "version": "0.4.0",
                 "from": "@fake_renderer_package@latest",
                 "resolved": "https://test_example.com.tgz"
               }
              }
            }'
        with_stubbed_script(@context, Argo::SCRIPT_PATH) do
          ShopifyCli::JsSystem.any_instance.stubs(:call).returns(result)
          old = Argo.const_get(:ARGO_ADMIN_RENDERER_PACKAGE)
          Argo.send(:remove_const, :ARGO_ADMIN_RENDERER_PACKAGE)
          Argo.const_set(:ARGO_ADMIN_RENDERER_PACKAGE, '@fake_renderer_package')
          config = @argo.config(@context)
          Argo.send(:remove_const, :ARGO_ADMIN_RENDERER_PACKAGE)
          Argo.const_set(:ARGO_ADMIN_RENDERER_PACKAGE, old)
          assert_includes(config.keys, :renderer_version)
          assert_match(/^([0-9]\d*)\.([0-9]\d*)\.([0-9]\d*)$/, config[:renderer_version])
        end
      end

      def test_version_renderer_returns_argo_checkout_renderer_package_version
        result = 'yarn list v1.22.4
        ├─ @fake_renderer_package-react@0.3.4
        └─ @fake_renderer_package@0.3.4
        ✨  Done in 0.42s.'
        with_stubbed_script(@context, Argo::SCRIPT_PATH) do
          ShopifyCli::JsSystem.any_instance.stubs(:call).returns(result)
          old = Argo.const_get(:ARGO_CHECKOUT_RENDERER_PACKAGE)
          Argo.send(:remove_const, :ARGO_CHECKOUT_RENDERER_PACKAGE)
          Argo.const_set(:ARGO_CHECKOUT_RENDERER_PACKAGE, '@fake_renderer_package')
          config = @argo.config(@context)
          Argo.send(:remove_const, :ARGO_CHECKOUT_RENDERER_PACKAGE)
          Argo.const_set(:ARGO_CHECKOUT_RENDERER_PACKAGE, old)
          assert_includes(config.keys, :renderer_version)
          assert_match(/^([0-9]\d*)\.([0-9]\d*)\.([0-9]\d*)$/, config[:renderer_version])
        end
      end
    end
  end
end
