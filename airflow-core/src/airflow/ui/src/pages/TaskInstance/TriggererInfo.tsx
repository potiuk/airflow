/*!
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
import { Box, Table, Heading } from "@chakra-ui/react";
import { useTranslation } from "react-i18next";

import type { TaskInstanceResponse } from "openapi/requests/types.gen";
import Time from "src/components/Time";

export const TriggererInfo = ({ taskInstance }: { readonly taskInstance: TaskInstanceResponse }) => {
  const { t: translate } = useTranslation();

  return (
    <Box py={1}>
      <Heading py={1} size="sm">
        {translate("taskInstance.triggerer.title")}
      </Heading>
      <Table.Root striped>
        <Table.Body>
          <Table.Row>
            <Table.Cell>{translate("taskInstance.triggerer.class")}</Table.Cell>
            <Table.Cell>{taskInstance.trigger?.classpath}</Table.Cell>
          </Table.Row>
          <Table.Row>
            <Table.Cell>{translate("taskInstance.triggerer.id")}</Table.Cell>
            <Table.Cell>{taskInstance.trigger?.id}</Table.Cell>
          </Table.Row>
          <Table.Row>
            <Table.Cell>{translate("taskInstance.triggerer.createdAt")}</Table.Cell>
            <Table.Cell>
              <Time datetime={taskInstance.trigger?.created_date} />
            </Table.Cell>
          </Table.Row>
          <Table.Row>
            <Table.Cell>{translate("taskInstance.triggerer.assigned")}</Table.Cell>
            <Table.Cell>{taskInstance.triggerer_job?.hostname}</Table.Cell>
          </Table.Row>
          <Table.Row>
            <Table.Cell>{translate("taskInstance.triggerer.latestHeartbeat")}</Table.Cell>
            <Table.Cell>
              <Time datetime={taskInstance.triggerer_job?.latest_heartbeat} />
            </Table.Cell>
          </Table.Row>
        </Table.Body>
      </Table.Root>
    </Box>
  );
};
