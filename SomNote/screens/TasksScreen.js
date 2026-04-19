import React from 'react';
import { View, Text, StyleSheet, FlatList, TouchableOpacity } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

const pendingTasks = [
  { id: '1', title: 'Finish SomNote app UI / Dhamee UI', priority: 'High', date: 'Mar 26, 2025' },
  { id: '2', title: 'YouTube channel content planning', priority: 'Medium', date: 'Mar 27, 2025' },
];

const completedTasks = [
  { id: '3', title: 'Promo affiliate program', date: 'Expired' },
  { id: '4', title: 'Exchange Sarafka update', date: 'Expired' },
];

export default function TasksScreen() {
  const renderPendingTask = ({ item }) => (
    <View style={styles.card}>
      <TouchableOpacity style={styles.checkboxContainer}>
        <Ionicons name="square-outline" size={24} color="#888" />
      </TouchableOpacity>
      <View style={styles.taskContent}>
        <Text style={styles.taskTitle}>{item.title}</Text>
        <View style={styles.taskMeta}>
          <Text style={[styles.taskPriority, { color: item.priority === 'High' ? '#FF4444' : '#FFA500' }]}>
            {item.priority}
          </Text>
          <View style={styles.dateContainer}>
            <Ionicons name="calendar-outline" size={14} color="#888" />
            <Text style={styles.taskDate}>{item.date}</Text>
          </View>
        </View>
      </View>
    </View>
  );

  const renderCompletedTask = ({ item }) => (
    <View style={[styles.card, { opacity: 0.6 }]}>
      <TouchableOpacity style={styles.checkboxContainer}>
        <Ionicons name="checkbox" size={24} color="#00C851" />
      </TouchableOpacity>
      <View style={styles.taskContent}>
        <Text style={[styles.taskTitle, { textDecorationLine: 'line-through', color: '#888' }]}>{item.title}</Text>
        <View style={styles.taskMeta}>
          <Text style={styles.taskDate}>{item.date}</Text>
        </View>
      </View>
    </View>
  );

  return (
    <View style={styles.container}>
      <View style={styles.filterContainer}>
        <TouchableOpacity style={[styles.filterTab, styles.filterTabActive]}>
          <Text style={styles.filterTextActive}>All 5</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.filterTab}>
          <Text style={styles.filterText}>Pending 2</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.filterTab}>
          <View style={{flexDirection:'row', alignItems:'center'}}>
            <Ionicons name="checkmark" size={14} color="#00C851" style={{marginRight:4}}/>
            <Text style={styles.filterText}>Done 3</Text>
          </View>
        </TouchableOpacity>
      </View>

      <FlatList
        data={[
          { type: 'header', title: 'Pending Tasks / Waqtiga Dhiman' },
          ...pendingTasks.map(t => ({ ...t, type: 'pending' })),
          { type: 'header', title: 'Completed (3)' },
          ...completedTasks.map(t => ({ ...t, type: 'completed' }))
        ]}
        keyExtractor={(item, index) => item.id || `header-${index}`}
        renderItem={({ item }) => {
          if (item.type === 'header') {
            return (
              <View style={styles.sectionHeader}>
                {item.title.includes('Completed') && (
                  <Ionicons name="checkmark-circle" size={18} color="#00C851" style={{marginRight: 6}} />
                )}
                {item.title.includes('Pending') && (
                  <Ionicons name="list" size={18} color="#FFA500" style={{marginRight: 6}} />
                )}
                <Text style={styles.sectionTitle}>{item.title}</Text>
              </View>
            );
          } else if (item.type === 'pending') {
            return renderPendingTask({ item });
          } else {
            return renderCompletedTask({ item });
          }
        }}
        contentContainerStyle={styles.listContainer}
        showsVerticalScrollIndicator={false}
      />

      <TouchableOpacity style={styles.fab}>
        <Ionicons name="add" size={32} color="#000" />
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a0a',
  },
  filterContainer: {
    flexDirection: 'row',
    padding: 16,
    justifyContent: 'space-between',
  },
  filterTab: {
    flex: 1,
    backgroundColor: '#1c1c1c',
    paddingVertical: 10,
    marginHorizontal: 4,
    borderRadius: 8,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#333',
  },
  filterTabActive: {
    borderColor: '#FFA500',
  },
  filterText: {
    color: '#888',
    fontSize: 14,
    fontWeight: 'bold',
  },
  filterTextActive: {
    color: '#fff',
    fontSize: 14,
    fontWeight: 'bold',
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    marginTop: 20,
    marginBottom: 10,
  },
  sectionTitle: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
  listContainer: {
    paddingHorizontal: 16,
    paddingBottom: 100,
  },
  card: {
    flexDirection: 'row',
    backgroundColor: '#1c1c1c',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#333',
    alignItems: 'center',
  },
  checkboxContainer: {
    marginRight: 16,
  },
  taskContent: {
    flex: 1,
  },
  taskTitle: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '500',
    marginBottom: 8,
  },
  taskMeta: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  taskPriority: {
    fontSize: 12,
    fontWeight: 'bold',
  },
  dateContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  taskDate: {
    color: '#888',
    fontSize: 12,
    marginLeft: 4,
  },
  fab: {
    position: 'absolute',
    bottom: 24,
    right: 24,
    backgroundColor: '#FFA500',
    width: 60,
    height: 60,
    borderRadius: 30,
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#FFA500',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.5,
    shadowRadius: 10,
    elevation: 8,
  },
});
