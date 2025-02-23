# Copyright 2019 OmiseGO Pte Ltd
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

defmodule OMG.ChildChainRPC.Web.Router do
  use OMG.ChildChainRPC.Web, :router

  pipeline :api do
    plug(:accepts, ["json"])
    plug(OMG.ChildChainRPC.Plugs.Health)
  end

  scope "/", OMG.ChildChainRPC.Web do
    pipe_through(:api)

    post("/block.get", Controller.Block, :get_block)
    post("/transaction.submit", Controller.Transaction, :submit)

    # NOTE: This *has to* be the last route, catching all unhandled paths
    match(:*, "/*path", Controller.Fallback, Route.NotFound)
  end
end
