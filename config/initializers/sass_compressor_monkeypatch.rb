# Source: https://github.com/tailwindlabs/tailwindcss/discussions/6738#discussioncomment-7921696
module SassCompressorMonkeypatch
  def call_processor(processor, input)
    super
  rescue SassC::SyntaxError => e
    raise unless processor == Sprockets::SassCompressor
    puts "Warning: Could not compress #{input[:filename]} with Sprockets::SassCompressor. Returning uncompressed result."
    metadata = (input[:metadata] || {}).dup
    metadata[:data] = input[:data]
    metadata
  end
end

Sprockets::Base.prepend(SassCompressorMonkeypatch)