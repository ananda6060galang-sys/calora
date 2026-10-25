import React from 'react';
import { ModerationQueueTable } from './ModerationQueueTable';
import { FoodRequest } from '../../types';

interface FoodRequestsTableProps {
  onOpenRequestModal: (req: FoodRequest) => void;
  isFullPage?: boolean;
}

export const FoodRequestsTable: React.FC<FoodRequestsTableProps> = ({
  onOpenRequestModal,
  isFullPage = false,
}) => {
  return (
    <ModerationQueueTable
      onOpenRequestModal={onOpenRequestModal}
      isFullPage={isFullPage}
    />
  );
};
