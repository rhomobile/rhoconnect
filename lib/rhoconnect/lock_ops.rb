
# Collection of methods for locking shared
# source documents when source_sync and client_sync
# need to access them
module LockOps
  def lock(doc,timeout=0,raise_on_expire=false)
    Store.lock(docname(doc),timeout,raise_on_expire) do
      yield self
    end
  end
end