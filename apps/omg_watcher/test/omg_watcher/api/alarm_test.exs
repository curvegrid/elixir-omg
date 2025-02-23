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

defmodule OMG.Watcher.API.AlarmTest do
  use ExUnit.Case, async: false

  alias OMG.Watcher.API.Alarm

  setup %{} do
    _ = Application.ensure_all_started(:omg_status)
    system_alarm = {:system_memory_high_watermark, []}
    system_disk_alarm = {{:disk_almost_full, "/dev/null"}, []}
    app_alarm = {:ethereum_client_connection, %{node: Node.self(), reporter: __MODULE__}}

    %{system_alarm: system_alarm, system_disk_alarm: system_disk_alarm, app_alarm: app_alarm}
  end

  test "if alarms are returned when there are no alarms raised", _ do
    _ = OMG.Status.Alert.Alarm.clear_all()
    {:ok, []} = Alarm.get_alarms()
  end

  test "if alarms are returned when there are alarms raised", %{
    system_alarm: system_alarm,
    system_disk_alarm: system_disk_alarm,
    app_alarm: app_alarm
  } do
    :ok = :alarm_handler.set_alarm(system_alarm)
    :ok = :alarm_handler.set_alarm(app_alarm)
    :ok = :alarm_handler.set_alarm(system_disk_alarm)

    {:ok,
     [
       {{:disk_almost_full, "/dev/null"}, []},
       {:ethereum_client_connection, %{node: :nonode@nohost, reporter: __MODULE__}},
       {:system_memory_high_watermark, []}
     ]} = Alarm.get_alarms()
  end
end
