

from fairpy import AgentList
from fairpy.allocations import Allocation
from typing import List, Tuple
import networkx as nx
import logging


logger = logging.getLogger(__name__)
cpdef proportional_division_equal_number_of_items_and_players(agents: AgentList):
    if not isBordaCount(agents):
        raise ValueError(f'Evaluation of items by the agents must be defined by "Board scores". but it is not')
    items = list(agents.all_items())
    cdef int k = len(items)
    logger.info("Started proportional division maintaining one item per agent. with %d agents and %d items", len(agents), k)
    if k != len(agents):
        raise ValueError(f"Numbers of agents and items must be identical, but they are not: {len(agents)}, {k}")
    cdef float threshold = (k-1)/2
    G = reduction_to_graph(agents, items, threshold)
    match = nx.max_weight_matching(G)
    if len(match) < k:
        logger.info("No maximum match was found in the graph, therefore there is no proportional division")
        return
    logger.info("A proportional division was found")
    bundles = bundles_from_edges(match, G)
    return Allocation(agents, bundles)




cpdef proportional_division_with_p_even(agents: AgentList):
    cdef int n = len(agents)
    cdef int k = len(agents.all_items())
    if k % n != 0:
        raise ValueError(f"The number of items must be multiple of the number of agents, but they are not: {k}, {n}")
    if not isBordaCount(agents):
        raise ValueError(f'Evaluation of items by the agents must be defined by "Board scores". but it is not')
    cdef int p = k/n
    if not isEven(p):
        raise ValueError(f"The number of items divided by the number of agents must be even but it is not:{k}/{n}={p}")
    
    logger.info("Started to apply proportional division in case n/k is even. For k=%d, n=%d, p=%d", k,n,p)
    unselected_items = list(agents.all_items())
    cdef list allocation = []
    for i in range(n):
        allocation.append([])
    _, allocation = selection_by_order(agents=agents, items=unselected_items ,allocation=allocation, num_iteration=int(p/2))
    return Allocation(agents, allocation)


cpdef proportional_division_with_number_of_agents_odd(agents: AgentList):
    cdef int n = len(agents)
    if isEven(n):
        raise ValueError(f"The number of agents must be odd but it is not: {n}")
    logger.info("The number of agents n equals %d is odd, therefore There is a proportional division and the proportional division function returns it", n)
    return proportional_division(agents)

cpdef proportional_division(agents: AgentList):
    cdef int n = len(agents)
    cdef int k = len(agents.all_items())
    if not k % n == 0:
        raise ValueError(f"The number of items must be multiple of the number of agents, but they are not: {k}, {n}")
    if isEven(k/n):
        logger.info("k/n equals %d is even, so we will run the appropriate function", int(k/n))
        return proportional_division_with_p_even(agents)
    if k/n == 1:
            raise ValueError(f"len(items)/len(agents) must be at least 3, but {k}/{n} == 1")
    if not isBordaCount(agents):
        raise ValueError(f'Evaluation of items by the agents must be defined by "Board scores". but it is not')
    logger.info("K/n is equal to %d odd, so the division is carried out according to the order that appears in the article", int(k/n))
    cdef int p = k/n - 3     # 3 ≤ k/n is odd
    cdef list q1 = []
    cdef list q2 = []
    cdef list q3 = []
    cdef list order = []
    cdef int i
    for i in range(n):
        order.append(i)
    for i in range(n, 0, -2):
        order.append(i-1)
    for i in range(n-1, 0, -2):
        order.append(i-1)
    for i in range(n-1, 0, -2):
        order.append(i-1)
    for i in range(n, 0, -2):
        order.append(i-1)

    items = list(agents.all_items())
    cdef list allocation = []
    for i in range(n):
        allocation.append([])
    unselected_items, allocation = selection_by_order(agents, items=items, allocation=allocation, order=order)
    _, allocation = selection_by_order(agents, items=unselected_items, allocation=allocation, num_iteration=int(p/2))
    return Allocation(agents, allocation)






#################    Helper function    #################
cpdef bundles_from_edges(match:set, G:nx.Graph):
    bundles = {}
    for edge in match:
        first_node = edge[0]
        second_node = edge[1]
        if G.nodes[first_node].get('isAgent', False):
            bundles[first_node] = [second_node]
        else:
            bundles[second_node] = [first_node]
    return bundles

cpdef reduction_to_graph(agents:AgentList, items:List, threshold:float):
    cdef val_item = 0
    G = nx.Graph()
    G.add_nodes_from(agents.agent_names())
    nx.set_node_attributes(G, True, 'isAgent')
    G.add_nodes_from(items)
    for agent in agents:
        for item in items:
            val_item = agent.value(item)
            if val_item >= threshold:
                G.add_edge(agent.name(), item)
    return G


cpdef isBordaCount(agents:AgentList):
    items = list(agents.all_items())
    cdef int k = len(items)
    cdef int n = len(agents)
    cdef int val = 0;
    for agent in agents:
        agent_values = set()
        for item in items:
            agent_values.add(agent.value(item))

        if len(agent_values) < n:
            return False
        
        for val in range(k):
            if val not in agent_values:
                return False
    return True
cpdef selection_by_order(agents:AgentList, items:list, allocation:List[list], num_iteration:int=1, order:list=None):
    cdef int i = 0
    cdef int index = 0
    cdef int iter = 0
    cdef int n = len(agents)
    cdef int favorite = 0
    if not order:
        order = createDefaultOrder(n)

    for iter in range(num_iteration):
        for i in range(len(order)):
            index = order[i]
            agent = agents[index]
            favorite_index = agent.best_index(items)
            favorite = items[favorite_index]
            allocation[index].append(favorite)
            items.remove(favorite)
    return items, allocation

cdef createDefaultOrder(int n):
    cdef list result = []
    cdef int i
    for i in range(n):
        result.append(i)
    for i in range(n,0,-1):
        result.append(i-1)

    return result

cdef isEven(n):
    return n % 2 == 0
