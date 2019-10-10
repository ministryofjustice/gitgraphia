# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/spec'
require 'gitgraphia'

describe Gitgraphia do
  # These are real commit SHAs on this repository from the `master` branch.
  # Using real hashes is unconventional, but git is immutable and I don't have to mock `git cat-file` this way.
  let(:root_commit_sha) { 'ab1527fbb47bbf110133a27f3a9043ba3a963062' }
  let(:child_of_root_commit_sha) { 'd102418484007c2ca572860977a0ac3327a5d7c8' }

  let(:gitgraphia) { Gitgraphia.new }

  describe '#parents_of' do
    let(:parent_shas) { gitgraphia.parents_of(sha) }

    describe 'the root commit' do
      let(:sha) { root_commit_sha }

      it 'has no parent' do
        _(parent_shas).must_equal []
      end
    end

    describe 'a single parent commit' do
      let(:sha) { child_of_root_commit_sha }

      it 'has a single parent' do
        _(parent_shas).must_equal [root_commit_sha]
      end
    end
  end

  describe '#tree_of' do
    let(:tree_sha) { gitgraphia.tree_of(sha) }

    describe 'a commit' do
      let(:sha) { root_commit_sha }

      it 'always has a tree hash' do
        _(tree_sha).must_equal '82e3a754b6a0fcb238b03c0e47d05219fbf9cf89'
      end
    end
  end

  describe '#tree_to_files' do
    let(:tree_sha) { "#{child_of_root_commit_sha}^{tree}" }
    let(:files) { gitgraphia.tree_to_files(tree_sha) }

    describe 'a tree' do
      it 'always has a list of files' do
        _(files).must_equal [
          { permissions: '100644', type: 'blob', sha: 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391', name: '.gitignore' },
          { permissions: '100644', type: 'blob', sha: '09d580dc72415ccb4828f4645231d3733ffb9505', name: 'README.md' }
        ]
      end
    end
  end

  describe 'object_of' do
    let(:object_lines) { gitgraphia.object_of(sha) }

    describe 'the root commit' do
      let(:sha) { root_commit_sha }

      it 'refers to a tree' do
        _(object_lines).must_include 'tree 82e3a754b6a0fcb238b03c0e47d05219fbf9cf89'
      end

      it 'has no parents reference' do
        _(object_lines.select { |line| line =~ /^parent/ })
          .must_be_empty("Commit #{sha} must not have a parent object reference")
      end
    end

    describe 'a single parent commit' do
      let(:sha) { child_of_root_commit_sha }

      it 'refers to a tree' do
        _(object_lines).must_include 'tree 48e230d5bb3080bd3dcb60eaaf3e536f7b531580'
      end

      it 'refers to a parent' do
        _(object_lines).must_include "parent #{root_commit_sha}"
      end
    end
  end
end
