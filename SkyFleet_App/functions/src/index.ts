/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import * as functions from "firebase-functions"; // functions namespace'ini doğru şekilde import ettik
import { onCall, HttpsFunction } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

// Firebase Admin SDK'yı başlatın.
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// Global seçenekleri koruyoruz
functions.setGlobalOptions({ maxInstances: 10 }); // setGlobalOptions'ı functions namespace'inden çağırıyoruz

// Ortak veri modeli tanımı
interface BirdDisplayData {
  id: string;
  halkaNumarasi: string;
  cinsiyet: string;
  isim?: string;
  notlar?: string;
  tur?: string;
  renk?: string;
  dogumTarihi?: string;
  fatherId?: string;
  motherId?: string;
  father?: BirdDisplayData | null; // Tipini BirdDisplayData | null olarak güncelledik
  mother?: BirdDisplayData | null; // Tipini BirdDisplayData | null olarak güncelledik
}

// Pedigri ağacını özyinelemeli olarak çeken yardımcı fonksiyon
async function fetchPedigreeParents(
  targetId: string,
  depth: number,
  maxDepth: number,
  userId: string,
  appId: string,
  fetchedBirds: Map<string, BirdDisplayData>
): Promise<BirdDisplayData | null> {
  if (depth > maxDepth) {
    return null;
  }
  if (fetchedBirds.has(targetId)) {
    return fetchedBirds.get(targetId)!;
  }

  let birdData: BirdDisplayData | null = null;

  // 1. Aktif kuş koleksiyonunda ara
  const activeBirdDoc = await db
    .collection("artifacts")
    .doc(appId)
    .collection("users")
    .doc(userId)
    .collection("birds")
    .doc(targetId)
    .get();

  if (activeBirdDoc.exists) {
    const data = activeBirdDoc.data()!;
    birdData = {
      id: activeBirdDoc.id,
      halkaNumarasi: data.halkaNumarasi || activeBirdDoc.id,
      isim: data.isim,
      cinsiyet: data.cinsiyet,
      notlar: data.notlar,
      tur: data.tur,
      renk: data.renk,
      dogumTarihi: data.dogumTarihi,
      fatherId: data.fatherId,
      motherId: data.motherId,
    };
  } else {
    // 2. PasifEbeveynler koleksiyonunda ara
    const passiveParentDoc = await db
      .collection("PasifEbeveynler")
      .doc(targetId)
      .get();

    if (passiveParentDoc.exists) {
      const data = passiveParentDoc.data()!;
      birdData = {
        id: passiveParentDoc.id,
        halkaNumarasi: data.halkaNumarasi || passiveParentDoc.id,
        cinsiyet: data.cinsiyet,
        notlar: data.notlar,
        fatherId: data.fatherId,
        motherId: data.motherId,
      };
    }
  }

  if (birdData) {
    fetchedBirds.set(birdData.id, birdData);

    // Babayı çek
    if (birdData.fatherId) {
      birdData.father = await fetchPedigreeParents(
        birdData.fatherId,
        depth + 1,
        maxDepth,
        userId,
        appId,
        fetchedBirds
      );
    }
    // Anneyi çek
    if (birdData.motherId) {
      birdData.mother = await fetchPedigreeParents(
        birdData.motherId,
        depth + 1,
        maxDepth,
        userId,
        appId,
        fetchedBirds
      );
    }
    return birdData;
  }

  return null;
}

// Ana Callable Cloud Function (v2 syntax)
export const getPedigreeTree: HttpsFunction = onCall(async (request) => {
  if (!request.auth) {
    logger.warn("Unauthenticated call to getPedigreeTree", {
      callerIp: request.rawRequest.ip,
    });
    throw new functions.https.HttpsError( // functions.https.HttpsError olarak çağrıldı
      "unauthenticated",
      "Bu işlemi yapabilmek için oturum açmalısınız."
    );
  }

  const userId = request.auth.uid;
  const targetId = request.data.targetId as string;
  const maxDepth = (request.data.maxDepth as number) || 4;
  const appId = request.data.appId as string;

  if (!targetId || !appId) {
    logger.warn("Invalid arguments for getPedigreeTree", {
      targetId,
      appId,
      userId,
    });
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Pedigri için hedef ID (targetId) ve uygulama ID'si (appId) belirtilmelidir."
    );
  }

  const fetchedBirds = new Map<string, BirdDisplayData>();
  const pedigreeTree = await fetchPedigreeParents(
    targetId,
    1,
    maxDepth,
    userId,
    appId,
    fetchedBirds
  );

  if (!pedigreeTree) {
    logger.info("Pedigree not found", { targetId, appId, userId });
    throw new functions.https.HttpsError(
      "not-found",
      "Belirtilen ID'ye sahip kuş veya pasif ebeveyn bulunamadı."
    );
  }

  return pedigreeTree;
});
