require 'soup'

describe Soup do

  describe "when unflavoured or based" do
    before(:each) { Soup.class_eval { @database_config = nil; @tuple_class = nil } }
    it "should use the default database config" do
      # I think this set of mock / expectations might be super wrong
      Soup::DEFAULT_CONFIG.should_receive(:merge).with({}).and_return(Soup::DEFAULT_CONFIG)
      Soup.tuple_class.should_receive(:prepare_database).with(Soup::DEFAULT_CONFIG)
      Soup.prepare
    end
  
    it "should use the default tuple implementation" do
      # No real idea how to mock the require, or use aught but Secret Knowledge that AR == Default
      Soup.tuple_class.should == Soup::Tuples::ActiveRecordTuple
      Soup::Tuples::ActiveRecordTuple.should_receive(:prepare_database)
      Soup.prepare
    end
  
  end

  describe "when being based" do
    before(:each) { Soup.class_eval { @database_config = nil; @tuple_class = nil } }
  
    it "should allow the base of the soup to be set" do
      Soup.should respond_to(:base=)
    end
  
    it "should use the new base when preparing the soup" do
      bouillabaisse = {:database => 'fishy.db', :adapter => 'fishdb'} 
      Soup.base = bouillabaisse
      Soup.tuple_class.should_receive(:prepare_database).with(bouillabaisse)
      Soup.prepare
    end
  
    it "should merge incomplete bases with the default" do
      tasteless = {:database => 'water.db'}
      Soup.base = tasteless
      Soup.tuple_class.should_receive(:prepare_database).with(Soup::DEFAULT_CONFIG.merge(tasteless))
      Soup.prepare
    end
  
    it "should allow the base to be reset" do
      bouillabaisse = {:database => 'fishy.db', :adapter => 'fishdb'} 
      Soup.base = bouillabaisse
      Soup.tuple_class.should_receive(:prepare_database).once.with(bouillabaisse).ordered
      Soup.prepare
    
      gazpacho = {:database => 'tomato.db', :adapter => 'colddb'}
      Soup.base = gazpacho
      Soup.tuple_class.should_receive(:prepare_database).once.with(gazpacho).ordered
      Soup.prepare
    end
  
    it "should not allow old bases to interfere with new ones" do
      bouillabaisse = {:database => 'fishy.db', :adapter => 'fishdb'} 
      Soup.base = bouillabaisse
      Soup.tuple_class.should_receive(:prepare_database).once.with(bouillabaisse).ordered
      Soup.prepare
    
      tasteless = {:database => 'water.db'}
      Soup.base = tasteless
      Soup.tuple_class.should_receive(:prepare_database).once.with(Soup::DEFAULT_CONFIG.merge(tasteless)).ordered
      Soup.tuple_class.should_not_receive(:prepare_database).with(bouillabaisse.merge(tasteless))
      Soup.prepare
    end
  end

  describe "when being flavoured" do
    before(:each) { Soup.class_eval { @database_config = nil; @tuple_class = nil } }
 
    it "should allow the soup to be flavoured" do
      Soup.should respond_to(:flavour=)
    end
  
    it "should determine the tuple class based on the flavour" do
      require 'soup/tuples/data_mapper_tuple'
      Soup.flavour = :data_mapper
      Soup.tuple_class.should == Soup::Tuples::DataMapperTuple
    end
  
    it "should allow the flavour to be set multiple times" do
      require 'soup/tuples/data_mapper_tuple'
      Soup.flavour = :data_mapper
      Soup.tuple_class.should == Soup::Tuples::DataMapperTuple
    
      require 'soup/tuples/sequel_tuple'
      Soup.flavour = :sequel
      Soup.tuple_class.should_not == Soup::Tuples::DataMapperTuple
      Soup.tuple_class.should == Soup::Tuples::SequelTuple
    end
  
    it "should use have no tuple class if the flavour is unknowable" do
      Soup.flavour = :shoggoth
      Soup.tuple_class.should == nil
    end
  end

  describe "when adding data to the Soup directly" do
    before(:each) do
      Soup.base = {:database => "soup_test.db"}
      Soup.flavour = :active_record
      Soup.prepare
      clear_database
    end
  
    it "should create a new snip" do
      attributes = {:name => 'monkey'}
      Snip.should_receive(:new).with(attributes).and_return(mock('snip', :null_object => true))
      Soup << attributes
    end
  
    it "should save the snip" do
      attributes = {:name => 'monkey'}
      Snip.should_receive(:new).with(attributes).and_return(snip = mock('snip'))
      snip.should_receive(:save)
      Soup << attributes    
    end
  end

  describe "when sieving the soup" do
    before(:each) do
      Soup.base = {:database => "soup_test.db"}
      Soup.flavour = :active_record
      Soup.prepare
      clear_database
      @james = Soup << {:name => 'james', :spirit_guide => 'fox', :colour => 'blue', :powers => 'yes'}
      @murray = Soup << {:name => 'murray', :spirit_guide => 'chaffinch', :colour => 'red', :powers => 'yes'}
    end
    
    it "should find snips by name if the parameter is a string" do
      Soup['james'].should == @james
    end
    
    it "should find snips using exact matching of keys and values if the parameter is a hash" do
      Soup[:name => 'murray'].should == @murray
    end
    
    it "should match using all parameters" do
      Soup[:powers => 'yes', :colour => 'red'].should == @james
    end

    it "should return an array if more than one snip matches" do
      Soup[:powers => 'yes'].should == [@james, @murray]
    end
  end
  
  describe "when deleting snips" do
    before(:each) do
      Soup.base = {:database => "soup_test.db"}
      Soup.flavour = :active_record
      Soup.prepare
      clear_database
    end
    
    it "should allow deletion of snips" do
      snip = Soup << {:name => 'test', :content => 'content'}
      Soup['test'].should == snip
      
      Soup.destroy('test')
      Soup['test'].should be_empty
    end
    
  end
end