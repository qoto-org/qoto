require 'rails_helper'

RSpec.describe ActivityPub::Activity::Delete do
  let(:sender) { Fabricate(:account, domain: 'example.com') }
  let(:status) { Fabricate(:status, account: sender, uri: 'foobar') }

  let(:json) do
    {
      '@context': 'https://www.w3.org/ns/activitystreams',
      id: 'foo',
      type: 'Delete',
      actor: ActivityPub::TagManager.instance.uri_for(sender),
      object: ActivityPub::TagManager.instance.uri_for(status),
      signature: 'foo',
    }.with_indifferent_access
  end

  describe '#perform' do
    subject { described_class.new(json, sender) }

    before do
      subject.perform
    end

    it 'deletes sender\'s status' do
      expect(Status.find_by(id: status.id)).to be_nil
    end
  end

  def concurrently(c, &block)
    threads = c.times.map { Thread.new(&block) }
    threads.each(&:join)
  end

  context 'when the status is a reply to a local status' do
    describe '#perform' do
      subject { described_class.new(json, sender) }
      let!(:parent)    { Fabricate(:account) }
      let!(:follower)  { Fabricate(:account, username: 'follower', protocol: :activitypub, domain: 'example.com', inbox_url: 'http://example.com/inbox') }
      let!(:thread)    { Fabricate(:status, account: parent) }
      let!(:status)    { Fabricate(:status, account: sender, uri: 'foobar', thread: thread) }

      before do
        stub_request(:post, 'http://example.com/inbox').to_return(status: 200)
        follower.follow!(parent)
        subject.perform
      end

      it 'deletes sender\'s status' do
        expect(Status.find_by(id: status.id)).to be_nil
      end

      it 'sends delete activity to followers of account of replied-to post' do
        expect(a_request(:post, 'http://example.com/inbox')).to have_been_made.once
      end

      it 'does not re-send delete activity to followers of account of replied-to post' do
        concurrently(5) { described_class.new(json, sender).perform }
        expect(a_request(:post, 'http://example.com/inbox')).to have_been_made.once
      end
    end
  end

  context 'when the status has been reblogged' do
    describe '#perform' do
      subject { described_class.new(json, sender) }
      let!(:reblogger) { Fabricate(:account) }
      let!(:follower)  { Fabricate(:account, username: 'follower', protocol: :activitypub, domain: 'example.com', inbox_url: 'http://example.com/inbox') }
      let!(:reblog)    { Fabricate(:status, account: reblogger, reblog: status) }

      before do
        stub_request(:post, 'http://example.com/inbox').to_return(status: 200)
        follower.follow!(reblogger)
        subject.perform
      end

      it 'deletes sender\'s status' do
        expect(Status.find_by(id: status.id)).to be_nil
      end

      it 'sends delete activity to followers of rebloggers' do
        expect(a_request(:post, 'http://example.com/inbox')).to have_been_made.once
      end

      it 'does not re-send delete activity to followers of rebloggers twice' do
        concurrently(5) { described_class.new(json, sender).perform }
        expect(a_request(:post, 'http://example.com/inbox')).to have_been_made.once
      end
    end
  end
end
