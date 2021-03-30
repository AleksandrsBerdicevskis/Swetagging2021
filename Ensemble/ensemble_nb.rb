#This script runs the ensemble method described in section 4.5 in the paper. The Ruby gem NBayes must be installed before running the script.

require 'nbayes'

inpath = "EnsembleInput" #Path to input files. Train2 = 75% of the original test set, Test2 = 25% (see the paper)
outpath = "EnsembleOutput" #Path where output will be stored
corpora = ["Eukalyptus", "TalbankenSBX","TalbankenUD"]

nbayes = NBayes::Base.new
method = "choose_tagger" #legacy variable. Can in principle be set to "choose_tag", and then naive Bayes will be trained to choose not the "most probable" tagger, but the "most probable" tag. However, input will have to reformatted then (and the results are likely to be worse).

trainon = "all" #what to take into account when training (and testing)? Options: "tags", "token", "all". "All" gives best results.

@default = "best" #will pick the best (first in the list) tagger at training time if there is no correct answer
minj = 2 #Where to start when looping through taggers. Default = 2: from bert
maxj = -1 #Where to stop. -1: all, -2: no hunpos; -3; no hunpos and marmot. Adjust if other taggers are used.

fast = false #set to true if you want to run the "fast" taggers (Hunpos, Marmot, Bert) only
votingrange = [2,3,4,5,6]
if fast then votingrange = [2,5,6] end
if fast then addendum = "_fast" else addendum = "" end

#which label assign to this word? Go through the list of taggers left to right, pick the first which works
def find_category(line1, taggers, method)
    category = "none"
    if method == "choose_tag"
        category = line1[1]
    elsif method == "choose_tagger"
        line1[2..-1].each.with_index do |response,ind|
            if response == line1[1]
                category = taggers[ind]
                break
            end
            if @default == "best"
                category = taggers[taggers.keys[0]]
            elsif default == "random"
                category = taggers[rand(taggers.length)] #random choice of tagger if there is no correct one. 
            end
        end
    end 
    return category
end

#creating output files
infofile = File.open("#{outpath}\\ensemble_info_train#{addendum}.tsv","w:utf-8")
infofile2 = File.open("#{outpath}\\ensemble_info_test_#{trainon}#{addendum}.tsv","w:utf-8")
infofile.puts "corpus\tfold\tat_least_one_is_correct\tbert_correct\tbert_wrong_some_other_correct\tjust_hunpos\tvoting\tweighted_voting\ttotal"
infofile2.puts "corpus\tfold\tat_least_one_is_correct\tbert_correct\tbert_wrong_some_other_correct\tjust_hunpos\tvoting\tweighted_voting\tbayes\ttotal"

#manually set weights for weighted voting (not described in the paper)
weights = {"1Bert" => 0.8, "2Flair"=> 0.7, "3Stanza"=> 0.5, "4Marmot" => 0.4, "5Hunpos" => 0}

corpora.each do |corpus|
    STDERR.puts corpus
    
    for i in 1..5 
        chosen_taggers = Hash.new(0)
        STDERR.puts i
        taggers = {}
        trainfile = File.open("#{inpath}\\#{corpus}_#{i}_train2.tsv","r:utf-8")
        testfile = File.open("#{inpath}\\#{corpus}_#{i}_test2.tsv","r:utf-8")
        predfile = File.open("#{outpath}\\#{corpus}_#{i}_test2_pred#{addendum}.tsv","w:utf-8")

        #initializing variables
        ntotal = 0.0
        nsomecorrect = 0.0
        nnotbert = 0.0
        nbert = 0.0
        nvote = 0.0
        nwvote = 0.0
        justhunpos = 0.0
        testbayes = 0.0
        testtotal = 0.0

        
        trainfile.each_line.with_index do |line, index|
            somecorrect = false
            if index == 0 
                line2 = line.strip.split("\t")
                line2[2..-1].each.with_index do |tagger, index|
                    taggers[index] = tagger 
                    #STDERR.puts tagger
                end 
            else #training
                if line.strip != ""
                    line2 = line.strip.split("\t")
                    votes = []
                    ntotal += 1
                    token = line2[0]
                    gold = line2[1]
                    for j in 2..6
                        if line2[j] == gold
                            nsomecorrect += 1
                            somecorrect = true
                            if j == 6
                                justhunpos += 1
                            end
                            break
                        end
                    end
                    wtaghash = Hash.new(0)
                    
                    for j in votingrange
                        votes << line2[j]
                        wtaghash[line2[j]] += weights[taggers[j-2]]
                    end
                    #STDERR.puts wtaghash
                    tagwvote = wtaghash.max_by{|k,v| v}[0]
                    #STDERR.puts tagwvote
                    if tagwvote == gold
                        nwvote += 1
                    end
                    
                    if somecorrect and line2[2] != gold
                        nnotbert += 1
                    end
                    if line2[2] == gold
                        nbert += 1
                    end
                    tagvote = votes.max_by {|i| votes.count(i)}
                    if tagvote == gold
                        nvote += 1
                    end
                    
                    category = find_category(line2, taggers, method) #which label assign to this word? Go through the list of taggers left to right, pick the first which works
                    if trainon == "tags"
                        text = line2[minj..maxj] #the array of tags 
                    elsif trainon == "token"
                        text = [token] #the array of tags 
                    elsif  trainon == "all"
                        text = line2[minj..maxj]
                        if fast then text = [line2[2],line2[5],line2[6]] end
                        text << token
                    end
                    
                   
                    nbayes.train(text, category) #train the naive baeys: this word + this array of tags gets this category (label)
                end
            end
        end
        infofile.puts "#{corpus}\t#{i}\t#{(nsomecorrect/ntotal).round(4)}\t#{(nbert/ntotal).round(4)}\t#{(nnotbert/ntotal).round(4)}\t#{(justhunpos/ntotal).round(4)}\t#{(nvote/ntotal).round(4)}\t#{(nwvote/ntotal).round(4)}\t#{ntotal}"  #output info about the train file  

        ntotal = 0.0
        nsomecorrect = 0.0
        nnotbert = 0.0
        nbert = 0.0
        nvote = 0.0
        nwvote = 0.0
        justhunpos = 0.0
        testbayes = 0.0

        #testing
        testfile.each_line.with_index do |line, index|
            if index > 0
                if line.strip != ""
                    ntotal += 1
                    
                    line2 = line.strip.split("\t")
                    votes = []
                    
                    token = line2[0]
                    gold = line2[1]
                    for j in 2..6
                        if line2[j] == gold
                            nsomecorrect += 1
                            somecorrect = true
                            if j == 6
                                justhunpos += 1
                            end
                            break
                        end
                    end
                    wtaghash = Hash.new(0)
                    
                    for j in votingrange
                        votes << line2[j]
                        wtaghash[line2[j]] += weights[taggers[j-2]]
                    end
                    #STDERR.puts wtaghash
                    tagwvote = wtaghash.max_by{|k,v| v}[0] #weighted voting
                    #STDERR.puts tagwvote
                    if tagwvote == gold
                        nwvote += 1
                    end
                    
                    if somecorrect and line2[2] != gold
                        nnotbert += 1
                    end
                    if line2[2] == gold
                        nbert += 1
                    end
                    tagvote = votes.max_by {|i| votes.count(i)} #simple voting
                    if tagvote == gold
                        nvote += 1
                    end
                    
                    text = line2[2..-1]

                    if trainon == "tags"
                        text = line2[minj..maxj] #the array of tags 
                    elsif trainon == "token"
                        text = [token] #the array of tags 
                    elsif  trainon == "all"
                        text = line2[minj..maxj]
                        if fast then text = [line2[2],line2[5],line2[6]] end
                        text << token
                    end
                    result = nbayes.classify(text) #Ask naive Bayes how to label the token
                    if method == "choose_tagger"
                        chosen_tagger = result.max_class #choose the most probable tagger
                        chosen_taggers[chosen_tagger] += 1 
                        chosen_tag = text[taggers.key(chosen_tagger)] #which tag does this tagger suggest?
                    elsif method == "choose_tag"
                        chosen_tag = result.max_class
                    end
                    output_line = "#{line2[0]}\t#{chosen_tag}\t#{chosen_tagger}" 
                    taggers.values.each do |tagger|
                        output_line << "\t#{result[tagger]}" #add info about the probabilities assigned to each tagger
                    end
                    predfile.puts output_line
                    #category = find_category(line1, taggers, method)
                    
                    if chosen_tag == gold
                        testbayes += 1
                    end
                else
                    predfile.puts
                end
            end
        end        

        infofile2.puts "#{corpus}\t#{i}\t#{(nsomecorrect/ntotal).round(4)}\t#{(nbert/ntotal).round(4)}\t#{(nnotbert/ntotal).round(4)}\t#{(justhunpos/ntotal).round(4)}\t#{(nvote/ntotal).round(4)}\t#{(nwvote/ntotal).round(4)}\t#{(testbayes/ntotal).round(4)}\t#{ntotal}"    
        
        #STDOUT.puts "#{chosen_taggers}" #how often each tagger gets chosen

    end
    
end
