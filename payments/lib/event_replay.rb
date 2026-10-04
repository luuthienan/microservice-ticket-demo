# Moves a consumer group's committed offsets so its listeners read events again. Stop the group's
# listener first: Kafka rejects offset commits from outside a group that has live members.
# Listeners must be safe to run twice for the same event (see CONTEXT.md, Version).
class EventReplay
  # from: "earliest", "timestamp:<iso8601>", or "offset:<partition>:<offset>" (that partition of every topic).
  def initialize(group, topics, from:, consumer: nil)
    @group = group
    @topics = topics
    @from = from
    @consumer = consumer
  end

  def call
    list = Rdkafka::Consumer::TopicPartitionList.new
    @topics.each { |topic| list.add_topic_and_partitions_with_offsets(topic, offsets_for(topic)) }
    consumer.commit(list, false)
  ensure
    consumer.close
  end

  private

  def consumer
    @consumer ||= EventBus.consumer(@group)
  end

  def partitions(topic)
    consumer.metadata(topic).topics.first[:partitions].map { |partition| partition[:partition_id] }
  end

  def offsets_for(topic)
    case @from
    when "earliest"
      partitions(topic).index_with { |partition| consumer.query_watermark_offsets(topic, partition).first }
    when /\Atimestamp:(.+)\z/
      at = Time.iso8601(Regexp.last_match(1))
      query = Rdkafka::Consumer::TopicPartitionList.new
      query.add_topic_and_partitions_with_offsets(topic, partitions(topic).index_with { at })
      consumer.offsets_for_times(query).to_h.fetch(topic).to_h { |tp| [tp.partition, tp.offset] }
    when /\Aoffset:(\d+):(\d+)\z/
      { Regexp.last_match(1).to_i => Regexp.last_match(2).to_i }
    else
      raise ArgumentError, "FROM must be earliest, timestamp:<iso8601> or offset:<partition>:<offset>"
    end
  end
end
