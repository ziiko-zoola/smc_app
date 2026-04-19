import React from 'react';
import { View, Text, StyleSheet, FlatList, TouchableOpacity } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

const dummyNotes = [
  { id: '1', title: 'Welcome to SomNote! 👋', content: 'Tani waa tusaale Note. Waad tafatiri kartaa ama tirtiri kartaa.', date: 'Mar 25, 2025 · 12:35 PM', pinned: true },
  { id: '2', title: 'Ideas for YouTube Content', content: '• React Native Tutorial\n• Somali Tech App Review', date: 'Mar 24, 2025 · 09:15 PM', pinned: false },
  { id: '3', title: 'Shopping List / Liiska Soo Gadashada', content: '• Internet Package\n• Coffee Beans\n• Groceries', date: 'Mar 23, 2025 · 06:40 PM', pinned: false },
];

export default function NotesScreen() {
  const renderNoteCard = ({ item }) => (
    <TouchableOpacity style={styles.card}>
      <View style={styles.cardHeader}>
        <Text style={styles.cardTitle}>{item.title}</Text>
        {item.pinned && <Ionicons name="star" size={16} color="#FFA500" />}
      </View>
      <Text style={styles.cardContent} numberOfLines={2}>{item.content}</Text>
      <Text style={styles.cardDate}>{item.date}</Text>
    </TouchableOpacity>
  );

  return (
    <View style={styles.container}>
      <View style={styles.searchContainer}>
        <Ionicons name="search" size={20} color="#888" style={styles.searchIcon} />
        <Text style={styles.searchText}>Search notes & ideas...</Text>
      </View>

      <View style={styles.statsContainer}>
        <View style={styles.statBox}>
          <Ionicons name="document-text" size={24} color="#FFA500" />
          <View style={styles.statTextContainer}>
            <Text style={styles.statNumber}>12</Text>
            <Text style={styles.statLabel}>Notes</Text>
          </View>
        </View>
        <View style={styles.statBox}>
          <Ionicons name="star" size={24} color="#FFA500" />
          <View style={styles.statTextContainer}>
            <Text style={styles.statNumber}>3</Text>
            <Text style={styles.statLabel}>Pinned</Text>
          </View>
        </View>
      </View>

      <Text style={styles.sectionTitle}>Recent Notes / Tii Ugu Dambeysay</Text>

      <FlatList
        data={dummyNotes}
        keyExtractor={(item) => item.id}
        renderItem={renderNoteCard}
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
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#1c1c1c',
    margin: 16,
    borderRadius: 12,
    padding: 12,
    borderWidth: 1,
    borderColor: '#333',
  },
  searchIcon: {
    marginRight: 10,
  },
  searchText: {
    color: '#888',
    fontSize: 16,
  },
  statsContainer: {
    flexDirection: 'row',
    paddingHorizontal: 16,
    marginBottom: 20,
    justifyContent: 'space-between',
  },
  statBox: {
    backgroundColor: '#1c1c1c',
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    borderRadius: 12,
    marginHorizontal: 5,
    borderWidth: 1,
    borderColor: '#333',
  },
  statTextContainer: {
    marginLeft: 12,
  },
  statNumber: {
    color: '#fff',
    fontSize: 20,
    fontWeight: 'bold',
  },
  statLabel: {
    color: '#888',
    fontSize: 12,
  },
  sectionTitle: {
    color: '#FFA500',
    fontSize: 16,
    fontWeight: 'bold',
    paddingHorizontal: 20,
    marginBottom: 10,
  },
  listContainer: {
    paddingHorizontal: 16,
    paddingBottom: 100,
  },
  card: {
    backgroundColor: '#1c1c1c',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#333',
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  cardTitle: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
    flex: 1,
  },
  cardContent: {
    color: '#aaa',
    fontSize: 14,
    marginBottom: 12,
    lineHeight: 20,
  },
  cardDate: {
    color: '#666',
    fontSize: 12,
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
