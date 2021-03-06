# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module GitProc

  #
  # The status of the Git repository.
  #
  # @!attribute [r] unmerged
  #   @return [Enumerable] a sorted list of unmerged files
  # @!attribute [r] modified
  #   @return [Enumerable] a sorted list of modified files
  # @!attribute [r] deleted
  #   @return [Enumerable] a sorted list of deleted files
  # @!attribute [r] added
  #   @return [Enumerable] a sorted list of files that have been added
  # @!attribute [r] unknown
  #   @return [Enumerable] a sorted list of unknown files
  class GitStatus
    attr_reader :unmerged, :modified, :deleted, :added, :unknown


    def initialize(lib)
      unmerged = []
      modified = []
      deleted = []
      added = []
      unknown = []

      stats = lib.porcelain_status.split("\n")

      stats.each do |s|
        stat = s[0..1]
        file = s[3..-1]
        #puts "stat #{stat} - #{file}"
        f = unquote(file)
        case stat
          when 'U ', ' U'
            unmerged << f
          when 'UU'
            unmerged << f
            modified << f
          when 'M ', ' M', 'MM'
            modified << f
          when 'MD'
            modified << f
            deleted << f
          when 'D ', ' D', 'DD'
            deleted << f
          when 'DU', 'UD'
            deleted << f
            unmerged << f
          when 'A ', ' A'
            added << f
          when 'AD'
            added << f
            deleted << f
          when 'AA', 'AU', 'UA'
            added << f
            unmerged << f
          when 'AM', 'MA'
            added << f
            modified << f
          when '??', '!!'
            unknown << f
          when 'R '
            old_file, new_file = file.split(' -> ')
            deleted << unquote(old_file)
            added << unquote(new_file)
          when 'C '
            old_file, new_file = file.split(' -> ')
            added << unquote(old_file)
            added << unquote(new_file)
          else
            raise "Do not know what to do with status #{stat} - #{file}"
        end
      end

      @unmerged = unmerged.sort.uniq.freeze
      @modified = modified.sort.uniq.freeze
      @deleted = deleted.sort.uniq.freeze
      @added = added.sort.uniq.freeze
      @unknown = unknown.sort.uniq.freeze
    end


    def unquote(file)
      file.match(/^"?(.*?)"?$/)[1]
    end


    # @return [Boolean] are there any changes in the index or working directory?
    def clean?
      @unmerged.empty? and @modified.empty? and @deleted.empty? and @added.empty? and @unknown.empty?
    end

  end

end
