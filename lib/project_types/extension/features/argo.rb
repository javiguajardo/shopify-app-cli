# frozen_string_literal: true
require 'base64'
require 'shopify_cli'
require 'json'

module Extension
  module Features
    class Argo
      include SmartProperties

      GIT_ADMIN_TEMPLATE = 'https://github.com/Shopify/argo-admin-template.git'
      GIT_CHECKOUT_TEMPLATE = 'https://github.com/Shopify/argo-checkout-template.git'
      ARGO_CHECKOUT_RENDERER_PACKAGE = '@shopify/argo-checkout'
      ARGO_ADMIN_RENDERER_PACKAGE = '@shopify/argo-admin'
      LIST_COMMAND = %w(list).freeze
      NPM_LIST_JSON_PARAMETER = %w(--json --depth=%s)
      YARN_LIST_PATTERN_PARAMETER = %w(--pattern).freeze

      SCRIPT_PATH = %w(build main.js).freeze

      class << self
        def admin
          @admin ||= Argo.new(
            setup: ArgoSetup.new(git_template: GIT_ADMIN_TEMPLATE),
            renderer_package: ARGO_ADMIN_RENDERER_PACKAGE,
          )
        end

        def checkout
          @checkout ||= Argo.new(
            setup: ArgoSetup.new(
              git_template: GIT_CHECKOUT_TEMPLATE,
              dependency_checks: [ArgoDependencies.node_installed(min_major: 10, min_minor: 16)]
            ),
            renderer_package: ARGO_CHECKOUT_RENDERER_PACKAGE,
          )
        end
      end

      property! :setup, accepts: Features::ArgoSetup
      property! :renderer_package, accepts: String
      # [ARGO_CHECKOUT_RENDERER_PACKAGE, ARGO_ADMIN_RENDERER_PACKAGE]

      def create(directory_name, identifier, context)
        setup.call(directory_name, identifier, context)
      end

      def config(context)
        filepath = File.join(context.root, SCRIPT_PATH)
        context.abort(context.message('features.argo.missing_file_error')) unless File.exist?(filepath)
        begin
          {
            renderer_version: extract_argo_renderer_version(context),
            serialized_script: Base64.strict_encode64(File.open(filepath).read.chomp),
          }
        rescue StandardError
          context.abort(context.message('features.argo.script_prepare_error'))
        end
      end

      private

      def extract_argo_renderer_version(context)
        js_system = ShopifyCli::JsSystem.new(ctx: context)
        result, _stat = js_system.call(
          yarn: ['list', '--pattern', '@shopify/argo-checkout'],
          npm: ['list', '@shopify/argo-admin', '--json', '--depth=0'],
          with_capture: true
        )
        if renderer_package == ARGO_ADMIN_RENDERER_PACKAGE
          hash_contents = JSON.parse(result)
          version = hash_contents["dependencies"][renderer_package]["version"]
        elsif renderer_package == ARGO_CHECKOUT_RENDERER_PACKAGE
          result = result.to_json
          packages = result.split('\n')
          packages.each_with_index do |package, index|
            if package.match(/argo-checkout@/)
              values = package.split('@')
              version = values[index]
            end
          end
        end
        version
      end
    end
  end
end
