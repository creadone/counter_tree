require "./spec_helper"

tree = CounterTree::Tree.new
tree_bytes = Bytes[130, 172, 98, 114, 97, 110, 99, 104, 101, 115, 95, 110, 117, 109, 9, 168, 98, 114, 97, 110, 99, 104, 101, 115, 153, 128, 129, 205, 4, 210, 130, 165, 116, 97, 98, 108, 101, 128, 165, 116, 111, 116, 97, 108, 0, 129, 205, 4, 211, 130, 165, 116, 97, 98, 108, 101, 128, 165, 116, 111, 116, 97, 108, 0, 128, 128, 128, 128, 128, 128]
timestamps = [20230201, 20230202, 20230203, 20230204, 20230205]

describe CounterTree do
  it "should increment and return 1" do
    result = tree.increment(1234)
    result.should eq(1_u64)
  end

  it "should reset global" do
    tree.increment(1234)
    tree.reset
    tree.sum(1234_u64).should eq(0)
  end

  it "should decrement and return 1" do
    result = tree.decrement(1234)
    result.should eq(1_u64)
  end

  it "should return sum" do
    tree.reset
    5.times{ tree.increment(1234_u64) }
    tree.sum(1234_u64).should eq(5_u64)
  end

  it "should return sum between dates" do
    tree.reset
    counter = tree.pick(1234_u64)
    timestamps.each{|t| counter.insert(t.to_u64, 1_u64) }
    key_from = counter.table.keys[1]
    key_to = counter.table.keys[3]
    tree.sum(1234_u64, key_from, key_to).should eq(3_u64)
  end

  it "should return hash between dates" do
    tree.reset
    counter = tree.pick(1234_u64)
    timestamps.each{|t| counter.insert(t.to_u64, 1_u64) }
    key_from = counter.table.keys[1]
    key_to = counter.table.keys.[3]
    result = tree.find(1234_u64, key_from, key_to)
    result.should eq({20230202 => 1, 20230203 => 1, 20230204 => 1})
  end

  it "should reset counter" do
    tree.reset
    5.times{ tree.increment(1234_u64) }
    tree.reset(1234_u64)
    tree.pick(1234_u64).total.should eq(0_u64)
  end

  it "should delete values between dates" do
    tree.reset
    counter = tree.pick(1234_u64)
    timestamps.each{|t| counter.insert(t.to_u64, 1_u64) }
    key_from = counter.table.keys[1]
    key_to = counter.table.keys[3]
    tree.delete(1234_u64, key_from, key_to)
    tree.pick(1234_u64).table.keys.size.should eq(2)
  end

  it "should delete values between dates over all counters" do
    tree.reset
    counter1 = tree.pick(1234_u64)
    counter2 = tree.pick(1235_u64)
    timestamps.each do |t|
      counter1.insert(t.to_u64, 1_u64)
      counter2.insert(t.to_u64, 1_u64)
    end

    key_from = counter1.table.keys[1]
    key_to = counter1.table.keys[3]

    tree.delete(key_from, key_to)
    tree.pick(1234_u64).table.keys.size.should eq(2)
    tree.pick(1235_u64).table.keys.size.should eq(2)
  end

    it "should return hash between timestamps over all counters" do
      tree.reset

      result = {
        1234 => {20230202 => 1, 20230203 => 1, 20230204 => 1},
        1235 => {20230202 => 1, 20230203 => 1, 20230204 => 1}
      }

      counter1 = tree.pick(1234_u64)
      counter2 = tree.pick(1235_u64)

      timestamps.each do |t|
        counter1.insert(t.to_u64, 1_u64)
        counter2.insert(t.to_u64, 1_u64)
      end

      key_from = counter1.table.keys[1]
      key_to = counter1.table.keys[3]

      tree.find(key_from, key_to).should eq(result)
    end

  it "should dump tree to msgpack" do
    tree.reset
    CounterTree.dump(tree).should eq(tree_bytes)
  end

  it "should load tree to msgpack" do
    tree1 = CounterTree.load(tree_bytes)
    tree1.class.should eq(tree.class)
  end

end
