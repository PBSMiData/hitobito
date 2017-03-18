require 'spec_helper'

describe Export::Pdf::Labels do

  let(:contactables) { [people(:top_leader).tap{ |u| u.update(nickname: 'Funny Name') }] }
  let(:label_format) { label_formats(:standard) }
  let(:pdf) { Export::Pdf::Labels.new(label_format).generate(contactables) }

  let(:subject) { PDF::Inspector::Text.analyze(pdf) }

  context 'for nickname' do
    it 'renders pp_post if pp_post given' do
      label_format.update!(nickname: true)
      expect(subject.strings).to include('Funny Name')
    end

    it 'ignores nickname if disabled' do
      expect(subject.strings.join(' ')).not_to include('Funny Name')
    end
  end

  context 'for pp_post' do
    it 'renders pp_post if pp_post given' do
      label_format.update!(pp_post: 'CH-3030 Bern')
      expect(subject.strings).to include("CH-3030 Bern  Post CH AG")
    end

    it 'ignores pp_post if not given' do
      label_format.update!(pp_post: '  ')
      expect(subject.strings.join(' ')).not_to include("Post CH AG")
    end
  end
end
