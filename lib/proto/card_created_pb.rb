# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: card_created.proto

require 'google/protobuf'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("card_created.proto", :syntax => :proto3) do
    add_message "CardCreated" do
      optional :id, :int64, 1
      optional :title, :string, 2
      optional :description, :string, 3
      optional :author_name, :string, 4
      optional :provider_name, :string, 5
      optional :image_url, :string, 6
      repeated :status_ids, :int64, 7
    end
  end
end

CardCreated = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("CardCreated").msgclass
