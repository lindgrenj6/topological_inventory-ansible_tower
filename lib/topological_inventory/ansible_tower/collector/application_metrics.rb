require "prometheus_exporter"
require "prometheus_exporter/server"
require "prometheus_exporter/client"
require 'prometheus_exporter/instrumentation'

module TopologicalInventory
  module AnsibleTower
    class Collector
      class ApplicationMetrics
        def initialize(port = 9394)
          return if port == 0

          configure_server(port)
          configure_metrics
        end

        def record_error
          @errors_counter&.observe(1)
        end

        def record_kafka_topic_length
          @persister_topic_length&.observe(get_topic_length)
        end

        def stop_server
          @server&.stop
        end

        private

        def configure_server(port)
          @server = PrometheusExporter::Server::WebServer.new(:port => port)
          @server.start

          PrometheusExporter::Client.default = PrometheusExporter::LocalClient.new(:collector => @server.collector)
        end

        def configure_metrics
          PrometheusExporter::Instrumentation::Process.start

          PrometheusExporter::Metric::Base.default_prefix = "topological_inventory_ansible_tower_collector_"

          @errors_counter = PrometheusExporter::Metric::Counter.new("errors_total", "total number of collector errors")
          @persister_topic_length = PrometheusExporter::Metric::Counter.new("persister_topic_length", "the length of the persister queue")

          @server.collector.register_metric(@errors_counter)
          @server.collector.register_metric(@persister_topic_length)
        end

        def get_topic_length
          # TODO: find out how to do this.
        end
      end
    end
  end
end
