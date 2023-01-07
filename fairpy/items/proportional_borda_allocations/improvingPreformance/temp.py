
from fairpy import AgentList
from typing import List, Tuple
import networkx as nx
from itertools import permutations
from fairpy import AgentList
# from utilsCpp import foo4


for x in range(20-1,-1,-1):
    print(x)

def get_agents_with_permutations_of_valuations(n,k):
    ans = []
    if n == 0 or k == 0:
        raise ValueError(f"n and k must be at least 0, but n={n}, k={k}")
    for i in permutations(range(k)):
        ans.append(list(i))
        if len(ans) == n:
            break
    return AgentList(ans)


def isBordaCount(agents:AgentList):
    items = list(agents.all_items())
    k = len(items)
    n = len(agents)
    
    for i in range(n):
        agent = agents[i]
        agent_values = set()
        for j in range(k):
            item = items[j]
            val = agent.value(item)
            agent_values.add(val)
      
        if len(agent_values) < n:
            return False
        for val in range(k):
            if val not in agent_values:
                return False
    return True

def equal(agents):
    if not isBordaCount(agents):
        raise ValueError(f'Evaluation of items by the agents must be defined by "Board scores". but it is not')
    
    
    items = list(agents.all_items())
    k = len(items)
    logger.info("Started proportional division maintaining one item per agent. with %d agents and %d items", len(agents), k)
    if k != len(agents):
        raise ValueError(f"Numbers of agents and items must be identical, but they are not: {len(agents)}, {k}")
    threshold = (k-1)/2
    G = utils.reduction_to_graph(agents, items, threshold)
    match = nx.max_weight_matching(G)
    if len(match) < k:
        logger.info("No maximum match was found in the graph, therefore there is no proportional division")
        return
    logger.info("A proportional division was found")
    bundles = utils.bundles_from_edges(match, G)
    return Allocation(agents, bundles)

# n = 5
# k = 5
# agentsI = get_agents_with_permutations_of_valuations(n, k)
# isBordaCount(agentsI)