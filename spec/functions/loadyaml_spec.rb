# frozen_string_literal: true

require 'spec_helper'

describe 'loadyaml' do
  it { is_expected.not_to be_nil }
  it { is_expected.to run.with_params.and_raise_error(ArgumentError, %r{wrong number of arguments}i) }

  context 'when a non-existing file is specified' do
    let(:filename) { '/tmp/doesnotexist' }

    it "'default' => 'value'" do
      allow(File).to receive(:exist?).and_call_original
      expect(File).to receive(:exist?).with(filename).and_return(false).once
      expect(YAML).not_to receive(:load_file)
      expect(subject).to run.with_params(filename, 'default' => 'value').and_return('default' => 'value')
    end
  end

  context 'when an existing file is specified' do
    let(:filename) { '/tmp/doesexist' }
    let(:data) { { 'key' => 'value', 'ķęŷ' => 'νậŀųề', 'キー' => '値' } }

    it "returns 'key' => 'value', 'ķęŷ' => 'νậŀųề', 'キー' => '値'" do
      allow(File).to receive(:exist?).and_call_original
      expect(File).to receive(:exist?).with(filename).and_return(true).once
      expect(YAML).to receive(:load_file).with(filename).and_return(data).once
      expect(subject).to run.with_params(filename).and_return(data)
    end
  end

  context 'when the file could not be parsed' do
    let(:filename) { '/tmp/doesexist' }

    it 'filename /tmp/doesexist' do
      allow(File).to receive(:exist?).and_call_original
      expect(File).to receive(:exist?).with(filename).and_return(true).once
      allow(YAML).to receive(:load_file).with(filename).once.and_raise(StandardError, 'Something terrible have happened!')
      expect(subject).to run.with_params(filename, 'default' => 'value').and_return('default' => 'value')
    end
  end

  context 'when an existing URL is specified' do
    let(:filename) { 'https://example.local/myhash.yaml' }
    let(:basic_auth) { { http_basic_authentication: ['', ''] } }
    let(:yaml) { 'Dummy YAML' }
    let(:data) { { 'key' => 'value', 'ķęŷ' => 'νậŀųề', 'キー' => '値' } }

    it {
      expect(OpenURI).to receive(:open_uri).with(filename, basic_auth).and_return(yaml)
      expect(YAML).to receive(:safe_load).with(yaml).and_return(data).once
      expect(subject).to run.with_params(filename).and_return(data)
    }
  end

  context 'when an existing URL (with username and password) is specified' do
    let(:filename) { 'https://user1:pass1@example.local/myhash.yaml' }
    let(:url_no_auth) { 'https://example.local/myhash.yaml' }
    let(:basic_auth) { { http_basic_authentication: ['user1', 'pass1'] } }
    let(:yaml) { 'Dummy YAML' }
    let(:data) { { 'key' => 'value', 'ķęŷ' => 'νậŀųề', 'キー' => '値' } }

    it {
      expect(OpenURI).to receive(:open_uri).with(url_no_auth, basic_auth).and_return(yaml)
      expect(YAML).to receive(:safe_load).with(yaml).and_return(data).once
      expect(subject).to run.with_params(filename).and_return(data)
    }
  end

  context 'when an existing URL (with username) is specified' do
    let(:filename) { 'https://user1@example.local/myhash.yaml' }
    let(:url_no_auth) { 'https://example.local/myhash.yaml' }
    let(:basic_auth) { { http_basic_authentication: ['user1', ''] } }
    let(:yaml) { 'Dummy YAML' }
    let(:data) { { 'key' => 'value', 'ķęŷ' => 'νậŀųề', 'キー' => '値' } }

    it {
      expect(OpenURI).to receive(:open_uri).with(url_no_auth, basic_auth).and_return(yaml)
      expect(YAML).to receive(:safe_load).with(yaml).and_return(data).once
      expect(subject).to run.with_params(filename).and_return(data)
    }
  end

  context 'when an existing URL could not be parsed, with default specified' do
    let(:filename) { 'https://example.local/myhash.yaml' }
    let(:basic_auth) { { http_basic_authentication: ['', ''] } }
    let(:yaml) { 'Dummy YAML' }

    it {
      expect(OpenURI).to receive(:open_uri).with(filename, basic_auth).and_return(yaml)
      expect(YAML).to receive(:safe_load).with(yaml).and_raise StandardError, 'Cannot parse data'
      expect(subject).to run.with_params(filename, 'default' => 'value').and_return('default' => 'value')
    }
  end

  context 'when a URL does not exist, with default specified' do
    let(:filename) { 'https://example.local/myhash.yaml' }
    let(:basic_auth) { { http_basic_authentication: ['', ''] } }
    let(:yaml) { 'Dummy YAML' }

    it {
      expect(OpenURI).to receive(:open_uri).with(filename, basic_auth).and_raise OpenURI::HTTPError, '404 File not Found'
      expect(subject).to run.with_params(filename, 'default' => 'value').and_return('default' => 'value')
    }
  end
end
