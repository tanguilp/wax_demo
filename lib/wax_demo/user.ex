defmodule WaxDemo.User do
  @moduledoc false
  @table :wax_demo_user_keys

  def init() do
    # since a user can have several credential IDs when using different FIDO2 authenticators,
    # we shall not use set here. It's is stored as: {username, credential_id, cose_key}
    :dets.open_file(@table, [{:type, :bag}])
  end

  def register_new_cose_key(user_id, user, key_id, cose_key, maybe_aaguid) do
    # FIXME: first check that the key_id is not already in use as per bullet point 18 here:
    # https://www.w3.org/TR/2019/PR-webauthn-20190117/#registering-a-new-credential
    :dets.insert(@table, {user_id, user, key_id, cose_key, maybe_aaguid})
  end

  def get_by_user_id(user_id) do
    :dets.lookup(@table, user_id)
  end

  def get_by_username(username) do
    :dets.select(@table, [{{:_, :"$1", :_, :_, :_}, [{:==, :"$1", username}], [:"$_"]}])
  end

  def print_keys() do
    :dets.traverse(
      @table,
      fn entry ->
        IO.inspect(entry)
        :continue
      end
    )
  end

  def clean_keys() do
    :dets.delete_all_objects(@table)
  end
end
