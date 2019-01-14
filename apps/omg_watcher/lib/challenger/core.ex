# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule OMG.Watcher.Challenger.Core do
  @moduledoc """
  Functional core of challenger
  """

  alias OMG.API.Block
  alias OMG.API.Crypto
  alias OMG.API.State.Transaction
  alias OMG.API.Utxo
  alias OMG.Watcher.Challenger.Challenge

  require Utxo

  @doc """
  Creates a challenge for exiting utxo.
  """
  @spec create_challenge(Block.t(), Block.t(), Utxo.Position.t()) :: Challenge.t()
  def create_challenge(creating_block, spending_block, Utxo.position(_, _, oindex) = utxo_exit) do
    owner =
      creating_block
      |> get_creating_transaction(utxo_exit)
      |> get_output_owner(oindex)

    {%Transaction.Signed{
       raw_tx: challenging_tx,
       sigs: sigs
     }, input_index} = get_spending_transaction_with_index(spending_block, utxo_exit)

    %Challenge{
      output_id: Utxo.Position.encode(utxo_exit),
      input_index: input_index,
      txbytes: challenging_tx |> Transaction.encode(),
      sig: find_sig(sigs, challenging_tx, owner)
    }
  end

  @doc """
  Checks whether database response is a block number which can be used to retrieve needed information to challenge.
  """
  @spec ensure_challengeable?(tuple()) :: {:ok, pos_integer()} | {:error, atom()}
  def ensure_challengeable?(spending_blknum_response)
  def ensure_challengeable?({:ok, :not_found}), do: {:error, :utxo_not_spent}
  def ensure_challengeable?({:ok, blknum}) when is_integer(blknum), do: {:ok, blknum}
  def ensure_challengeable?(error), do: error

  @spec get_creating_transaction(Block.t(), Utxo.Position.t()) :: Transaction.Signed.t()
  defp get_creating_transaction(
         %Block{
           transactions: txs,
           number: blknum
         },
         Utxo.position(blknum, txindex, _oindex)
       ) do
    {:ok, signed_tx} =
      txs
      |> Enum.fetch!(txindex)
      |> Transaction.Signed.decode()

    signed_tx
  end

  @spec get_output_owner(Transaction.Signed.t(), non_neg_integer()) :: Crypto.address_t()
  defp get_output_owner(%Transaction.Signed{raw_tx: raw_tx}, oindex) do
    raw_tx
    |> Transaction.get_outputs()
    |> Enum.fetch!(oindex)
    |> Map.fetch!(:owner)
  end

  # finds transaction in given block and input index spending given utxo
  @spec get_spending_transaction_with_index(Block.t(), Utxo.Position.t()) ::
          {Transaction.Signed.t(), non_neg_integer()} | false
  defp get_spending_transaction_with_index(%Block{transactions: txs}, utxo_pos) do
    txs
    |> Enum.map(&Transaction.Signed.decode/1)
    |> Enum.find_value(fn {:ok, %Transaction.Signed{raw_tx: tx} = tx_signed} ->
      # `Enum.find_value/2` allows to find tx that spends `utxo_pos` and return it along with input index in one run
      inputs = Transaction.get_inputs(tx)

      if input_index = Enum.find_index(inputs, &(&1 == utxo_pos)) do
        {tx_signed, input_index}
      else
        false
      end
    end)
  end

  defp find_sig(sigs, raw_tx, owner) do
    tx_hash = Transaction.hash(raw_tx)

    Enum.find(sigs, fn sig ->
      {:ok, owner} == Crypto.recover_address(tx_hash, sig)
    end)
  end
end
