#!/usr/bin/env ruby

# I expect that the adapter_settings_format.txt file is contained in the same directory as this script.
adapter_settings_format = File.join(__dir__, "adapter_settings_format.txt")
adapter_types = File.join(__dir__, "adapter_types.txt")

# Create a hash (dict for the pythonistas) to store the association of index name to index sequence.
index_seq_lookup = Hash.new

# Find all lines in `adapter_settings_format` that contain at least two comma-separated elements where
#  the second element looks like a nucleotide sequence and store the index name in the hash
#  indexed by the sequence.
File.open(adapter_settings_format, 'r')
    .each_line
    .map { |line| line.chomp.split(",") }
    .find_all { |split| (split.length >= 2) && (split[1] =~ /[acgtnACGTN]+/) }
    .each do |split|
        name = split.shift
        index_seq_lookup[name] = split
    end

# Go through the adapter_types.txt file and find all of the lines defining Illumina barcodes
# Each line is a comma-separated list of six columns:
# - Barcode name
# - Barcode type
# - SINGLEINDEX | DUALINDEX
# - ILLUMINA | MGI
# - List of combinatorial i5 IDs, separated by "|"

# For all Illumina barcodes:
# If there are no combinatorial index pairs, just add the name of the index into the index_name_lookup hash
#   index_name_lookup_all[seq] << name
# If there *are* combinatorial index paris:
#   add all possible [i7][i5] concatenations to index_name_lookup_i5fwd:
#     index_name_lookup_i5fwd[i7+i5] << name
#   add all possible [i7rc][i5] concatenations to index_name_lookup_i5rev:
#     index_name_lookup_i5fwd[i7rc+i5] << name

index_name_lookup_all = Hash.new{|h,k| h[k] = []}
index_name_lookup_allrev = Hash.new{|h,k| h[k] = []}
index_name_lookup_i5fwd = Hash.new{|h,k| h[k] = []}
index_name_lookup_i5rev = Hash.new{|h,k| h[k] = []}
index_name_lookup_i5i7rev = Hash.new{|h,k| h[k] = []}

# Tiny utility function for issuing a warning on stderr
def warn_missing_barcode(id)
    $stderr.puts "WARNING: I found a barcode '#{id}' in adapter_types.txt, but could not find the corresponding sequence in adapter_settings_format.txt"
end

# Utility function for reverse complementing a string of nucleotides.
def revcomp(sequence)
    sequence.reverse.tr!('wsatugcyrkmbdhvnATUGCYRKMBDHVN', 'WSTAACGRYMKVHDBNTAACGRYMKVHDBN')
end

File.open(adapter_types, 'r')
    .each_line
    .map{ |line| line.chomp }
    .drop(1)
    .reject{ |line| line =~ /^,/ }
    .reject{ |line| line =~ /^\s*$/ }
    .map{ |line| line.split(",") }
    .each { |id, seqtype, indextype, technology, terminus, i5ids, setname, publish|
        seqs = index_seq_lookup[id]
        if seqs.nil?
            warn_missing_barcode(id)
        elsif seqs.length == 1
            # If there is only one sequence, we're not dealing with a 10x quad barcode, so no need to add any suffix.
            seq = seqs.first
            index_name_lookup_all[seq] << id
            index_name_lookup_allrev[revcomp(seq)] << id
        else
            # If there *is* more than one sequence, store each with it's own id. I'm adding "(A)", "(B)", etc
            # to the end of each barcode id to distinguish them.
            seqs.zip(("A".."Z")).each { |seq, suffix| index_name_lookup_all[seq] << "#{id}(#{suffix})" }
            seqs.zip(("A".."Z")).each { |seq, suffix| index_name_lookup_allrev[revcomp(seq)] << "#{id}(#{suffix})" }
        end

        next if i5ids == nil
        next unless i5ids.include? "|"
        i5ids
            .split("|")
            .each{ |id2|
                i7seqs = index_seq_lookup[id]
                i5seqs = index_seq_lookup[id2]
                warn_missing_barcode(id) if i7seqs.nil?
                warn_missing_barcode(id2) if i5seqs.nil?
                next if i7seqs.nil? || i5seqs.nil?

                # We're expecting that these multiplex primers are not the 10x barcodes that have four barcodes per
                $stderr.puts "WARN: Did not expect multiple sequences for i7 sequence with ID '#{id}'" if i7seqs.length > 1
                $stderr.puts "WARN: Did not expect multiple sequences for i5 sequence with ID '#{id}'" if i5seqs.length > 1
                next if (i7seqs.length > 1) || (i5seqs.length > 1)
                i7seq = i7seqs.first
                i5seq = i5seqs.first

                # First, we store add the [i7+i5] sequence to the index_name_lookup_i5fwd hash
                full_seq = i7seq + i5seq
                index_name_lookup_i5fwd[full_seq] << "#{id}-#{id2}"
                # Second, we store the [i7+i5rc] sequence to the index_name_lookup_i5rev hash
                full_seq = i7seq + revcomp(i5seq)
                index_name_lookup_i5rev[full_seq] << "#{id}-#{id2}"
                # Lastly, we store the [i7rc+i5rc] sequence to the index_name_lookup_i5i7rev hash
                full_seq = revcomp(i7seq) + revcomp(i5seq)
                index_name_lookup_i5i7rev[full_seq] << "#{id}-#{id2}"
            }
    }

# Finally, we write two files with columns:
# - barcode sequence
# - barcode names (comma-separated)

File.open("barcodes_by_sequence.i5fwd.txt", 'w') do |out|
    out.puts "barcode_sequence\tbarcode_name"
    out.puts index_name_lookup_i5fwd
    .merge(index_name_lookup_all){ |key, new_ary, old_ary| new_ary + old_ary }
    .sort
    .map { |seq, names| [seq, names.join(",")].join("\t") }
end

File.open("barcodes_by_sequence.i5rev.txt", 'w') do |out|
    out.puts "barcode_sequence\tbarcode_name"
    out.puts index_name_lookup_i5rev
    .merge(index_name_lookup_all){ |key, new_ary, old_ary| new_ary + old_ary }
    .sort
    .map { |seq, names| [seq, names.join(",")].join("\t") }
end

File.open("barcodes_by_sequence.allrev.txt", 'w') do |out|
    out.puts "barcode_sequence\tbarcode_name"
    out.puts index_name_lookup_i5i7rev
    .merge(index_name_lookup_allrev){ |key, new_ary, old_ary| new_ary + old_ary }
    .sort
    .map { |seq, names| [seq, names.join(",")].join("\t") }
end