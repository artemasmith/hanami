module Hanami
  class CLI
    module Commands
      module Generate
        # @since 1.1.0
        # @api private
        class App < Command # rubocop:disable Metrics/ClassLength
          requires "environment"

          desc "Generate an app"

          argument :app, required: true, desc: "The application name (eg. `web`)"
          option :application_base_url, desc: "The app base URL (eg. `/api/v1`)"

          example [
            "admin                              # Generate `admin` app",
            "api --application-base-url=/api/v1 # Generate `api` app and mount at `/api/v1`"
          ]

          # @since 1.1.0
          # @api private
          #
          # rubocop:disable Metrics/AbcSize
          # rubocop:disable Metrics/MethodLength
          def call(app:, application_base_url: nil, **options)
            app      = Utils::String.underscore(app)
            template = options.fetch(:template)
            base_url = application_base_url || "/#{app}"
            context  = Context.new(app: app, base_url: base_url, test: options.fetch(:test), template: template, options: options)

            assert_valid_base_url!(context)

            generate_app(context)
            generate_routes(context)
            generate_layout(context)
            generate_template(context)
            generate_favicon(context)

            create_controllers_directory(context)
            create_assets_images_directory(context)
            create_assets_javascripts_directory(context)
            create_assets_stylesheets_directory(context)

            create_spec_features_directory(context)
            create_spec_controllers_directory(context)
            generate_layout_spec(context)

            inject_require_app(context)
            inject_mount_app(context)

            append_development_http_session_secret(context)
            append_test_http_session_secret(context)
          end
          # rubocop:enable Metrics/MethodLength
          # rubocop:enable Metrics/AbcSize

          private

          # @since 1.1.0
          # @api private
          def assert_valid_base_url!(context)
            if Utils::Blank.blank?(context.base_url) # rubocop:disable Style/GuardClause
              warn "`' is not a valid URL"
              exit(1)
            end
          end

          # @since 1.1.0
          # @api private
          def generate_app(context)
            source      = templates.find("application.erb")
            destination = project.app_application(context)

            generator.create(source, destination, context)
          end

          # @since 1.1.0
          # @api private
          def generate_routes(context)
            source      = templates.find("routes.erb")
            destination = project.app_routes(context)

            generator.create(source, destination, context)
          end

          # @since 1.1.0
          # @api private
          def generate_layout(context)
            source      = templates.find("layout.erb")
            destination = project.app_layout(context)

            generator.create(source, destination, context)
          end

          # @since 1.1.0
          # @api private
          def generate_template(context)
            source      = templates.find("template.#{context.template}.erb")
            destination = project.app_template(context)

            generator.create(source, destination, context)
          end

          # @since 1.1.0
          # @api private
          def generate_favicon(context)
            source      = templates.find("favicon.ico")
            destination = project.app_favicon(context)

            generator.copy(source, destination)
          end

          # @since 1.1.0
          # @api private
          def create_controllers_directory(context)
            source      = templates.find("gitkeep.erb")
            destination = project.keep(project.controllers(context))

            generator.create(source, destination, context)
          end

          # @since 1.1.0
          # @api private
          def create_assets_images_directory(context)
            source      = templates.find("gitkeep.erb")
            destination = project.keep(project.images(context))

            generator.create(source, destination, context)
          end

          # @since 1.1.0
          # @api private
          def create_assets_javascripts_directory(context)
            source      = templates.find("gitkeep.erb")
            destination = project.keep(project.javascripts(context))

            generator.create(source, destination, context)
          end

          # @since 1.1.0
          # @api private
          def create_assets_stylesheets_directory(context)
            source      = templates.find("gitkeep.erb")
            destination = project.keep(project.stylesheets(context))

            generator.create(source, destination, context)
          end

          # @since 1.1.0
          # @api private
          def create_spec_features_directory(context)
            source      = templates.find("gitkeep.erb")
            destination = project.keep(project.features_spec(context))

            generator.create(source, destination, context)
          end

          # @since 1.1.0
          # @api private
          def create_spec_controllers_directory(context)
            source      = templates.find("gitkeep.erb")
            destination = project.keep(project.controllers_spec(context))

            generator.create(source, destination, context)
          end

          # @since 1.1.0
          # @api private
          def generate_layout_spec(context)
            source      = templates.find("layout_spec.#{context.options.fetch(:test)}.erb")
            destination = project.app_layout_spec(context)

            generator.create(source, destination, context)
          end

          # @since 1.1.0
          # @api private
          def inject_require_app(context)
            content = "require_relative '../apps/#{context.app}/application'"
            path    = project.environment(context)

            generator.insert(path, content, after: /require_relative '\.\.\/lib\/.*'/)
          end

          # @since 1.1.0
          # @api private
          def inject_mount_app(context)
            content = "  mount #{context.app.classify}::Application, at: '#{context.base_url}'"
            path    = project.environment(context)

            generator.insert(path, content, after: /Hanami.configure do/)
          end

          # @since 1.1.0
          # @api private
          def append_development_http_session_secret(context)
            content = %(#{context.app.upcase}_SESSIONS_SECRET="#{project.app_sessions_secret}")
            path    = project.env(context, "development")

            generator.append(path, content)
          end

          # @since 1.1.0
          # @api private
          def append_test_http_session_secret(context)
            content = %(#{context.app.upcase}_SESSIONS_SECRET="#{project.app_sessions_secret}")
            path    = project.env(context, "test")

            generator.append(path, content)
          end
        end
      end
    end
  end
end
