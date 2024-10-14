import 'package:flutter/material.dart';

class RowListTraversalPolicy extends ReadingOrderTraversalPolicy {
    @override
    bool inDirection(FocusNode currentNode, TraversalDirection direction) {
        FocusNode row = currentNode.parent!;
        FocusNode list = row.parent!;

        if (direction == TraversalDirection.down || direction == TraversalDirection.up) {
            List<FocusNode> focusableChildren = list.children.toList();
            int index = focusableChildren.indexOf(row);

            if(index != -1) {
                if (direction == TraversalDirection.down && index + 1 < focusableChildren.length) {
                    focusableChildren[index + 1].children.firstOrNull?.requestFocus();
                    return true;
                } else if (direction == TraversalDirection.up && index > 0) {
                    focusableChildren[index - 1].children.firstOrNull?.requestFocus();
                    return true;
                }
            }
        }

        if(direction == TraversalDirection.right) {
            List<FocusNode> focusableChildren = row.children.toList();
            int index = focusableChildren.indexOf(currentNode);

            if(index != -1) {
                if(index == focusableChildren.length - 1)
                    return false;
            }
        }

        if(direction == TraversalDirection.left) {
            List<FocusNode> focusableChildren = row.children.toList();
            int index = focusableChildren.indexOf(currentNode);

            if(index != -1) {
                if(index == 0)
                    return false;
            }
        }

        return super.inDirection(currentNode, direction);
    }
}
