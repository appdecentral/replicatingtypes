# Conflict-Free Replicated Data Types (CRDTs) in Swift

_Author:_ Drew McCormack ([@drewmccormack](https://twitter.com/drewmccormack))<br>
_Site:_ [appdecentral.com](https://appdecentral.com)

This repo contains the Swift code introduced in the tutorial series on CRDTs at appdecentral.com.

### Related Posts

1. [Conflict-Free Replicated Data Types (CRDTs) in Swift](https://appdecentral.com/2020/07/12/conflict-free-replicated-data-types-crdts-in-swift/). An introduction to the series, what replicating types are, and the rules they follow.
2. [A First Replicating Type](https://appdecentral.com/2020/07/22/a-first-replicating-type/). Presents the first type in the series, a replicating register. With this simple type, you can develop complete apps in some cases.
3. [A First Replicating Collection](https://appdecentral.com/2020/07/22/first-replicating-collection/). Introduces the first collection type, a replicating add-only set.
4. [Time for Tombstones](https://appdecentral.com/2020/08/20/time-for-tombstones/). Introduces a set type that can be added to, and removed from. Addresses how you can handle time robustly, as well as introduce tombstones to handle deletion.
5. [Replicants All the Way Down](). Introduces a replicating dictionary type which recursively merges its values.