class DirectMongoDb
  attr_accessor :db

  def initialize db
    self.db = db
  end

  def find(collection, selector={}, opts={}, &block)
    EM::Synchrony.sleep(0.01)
    f = Fiber.current
    db.collection(collection).find(selector, opts) do |result|
      f.resume(result)
    end
    res = Fiber.yield
    yield res if block_given?
    res
  end

  def first(collection, selector={}, opts={}, &block)
    opts[:limit] = 1
    res = find(collection, selector, opts).first
    yield res if block_given?
    res
  end

  def insert(collection, *args)
    db.collection(collection).insert(*args)
    EM::Synchrony.sleep(0.01)
  end
  def update(collection, *args)
    db.collection(collection).update(*args)
    EM::Synchrony.sleep(0.01)
  end
  def save(collection, *args)
    db.collection(collection).save(*args)
    EM::Synchrony.sleep(0.01)
  end
  def remove(collection, *args)
    db.collection(collection).remove(*args)
    EM::Synchrony.sleep(0.01)
  end
end
